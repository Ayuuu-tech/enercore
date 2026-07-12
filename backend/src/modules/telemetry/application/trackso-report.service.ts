import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { allSiteKeys, siteKeyForPlantName } from '../../../common/trackso/site-map';

export type ReportFrequency = 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY';

const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

@Injectable()
export class TracksoReportService {
  private readonly logger = new Logger(TracksoReportService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  private get baseUrl(): string {
    return this.config.get<string>('TRACKSO_BASE_URL') ?? 'https://prodapi.trackso.in';
  }

  private get siteKeys(): string[] {
    const configured = this.config.get<string>('TRACKSO_SITE_KEYS');
    if (!configured) return allSiteKeys();
    return configured.split(',').map((k) => k.trim()).filter(Boolean);
  }

  private async login(): Promise<string> {
    const loginRes = await fetch(`${this.baseUrl}/v1/login`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json;charset=UTF-8',
        'authorization': this.config.get<string>('TRACKSO_AUTH_HEADER') ?? ''
      },
      body: JSON.stringify({
        email: this.config.get<string>('TRACKSO_EMAIL'),
        password: this.config.get<string>('TRACKSO_PASSWORD')
      })
    });
    if (!loginRes.ok) {
      throw new Error(`Trackso login failed with status: ${loginRes.status}`);
    }
    const loginData = await loginRes.json();
    const authToken = loginData.result?.auth_token;
    if (!authToken) {
      throw new Error('Trackso login response did not contain an auth token');
    }
    return authToken;
  }

  private async resolveSiteKey(plantId: string): Promise<string> {
    const plant = await this.prisma.plant.findUnique({ where: { id: plantId } });
    if (!plant) {
      throw new NotFoundException(`Plant with ID ${plantId} not found`);
    }
    const key = siteKeyForPlantName(plant.name);
    if (!key) {
      throw new BadRequestException(`Plant "${plant.name}" has no Trackso site mapping`);
    }
    return key;
  }

  // Computes the IST-calendar period containing the given date.
  private computeRange(frequency: ReportFrequency, dateMs: number): { from: number; to: number } {
    const ist = new Date(dateMs + IST_OFFSET_MS);
    const y = ist.getUTCFullYear();
    const m = ist.getUTCMonth();
    const d = ist.getUTCDate();

    const istStartToUtc = (yy: number, mm: number, dd: number) => Date.UTC(yy, mm, dd) - IST_OFFSET_MS;

    let from: number;
    let toExclusive: number;
    switch (frequency) {
      case 'DAILY':
        from = istStartToUtc(y, m, d);
        toExclusive = istStartToUtc(y, m, d + 1);
        break;
      case 'WEEKLY': {
        const dayOfWeek = (new Date(Date.UTC(y, m, d)).getUTCDay() + 6) % 7; // Monday = 0
        from = istStartToUtc(y, m, d - dayOfWeek);
        toExclusive = istStartToUtc(y, m, d - dayOfWeek + 7);
        break;
      }
      case 'MONTHLY':
        from = istStartToUtc(y, m, 1);
        toExclusive = istStartToUtc(y, m + 1, 1);
        break;
      case 'YEARLY':
        from = istStartToUtc(y, 0, 1);
        toExclusive = istStartToUtc(y + 1, 0, 1);
        break;
      default:
        throw new BadRequestException(`Invalid report frequency: ${frequency}`);
    }
    return { from, to: toExclusive - 1000 };
  }

  /**
   * Live per-device (inverter/meter) status + generation for a plant, straight
   * from Trackso. Trackso "units" are the real monitored devices at a site.
   */
  async getDevices(plantId: string): Promise<
    {
      id: string;
      name: string;
      type: string; // INVERTER | METER | OTHER
      status: string; // ACTIVE | ERROR | INACTIVE | UNKNOWN
      capacity: number | null;
      activePowerKw: number;
      dailyEnergyKwh: number;
      totalEnergyKwh: number; // cumulative counter, for billing
      acVoltage: number; // avg of the 3 phases (V)
      acCurrent: number; // sum of the 3 phases (A)
      acFrequency: number; // Hz
    }[]
  > {
    const siteKey = await this.resolveSiteKey(plantId);
    const authToken = await this.login();
    const headers = {
      'content-type': 'application/json;charset=UTF-8',
      'x-auth-token': authToken,
      'authorization': authToken,
    };

    // 1. List the site's units (inverters/meters)
    const unitsRes = await fetch(
      `${this.baseUrl}/units?siteKeys=${siteKey}&page=1&per=100`,
      { headers },
    );
    if (!unitsRes.ok) {
      throw new BadRequestException(`Failed to fetch Trackso units (status ${unitsRes.status})`);
    }
    const unitsData = await unitsRes.json();
    const elements: any[] = unitsData.result?.elements ?? [];

    // Classify a unit by its name: solar inverters vs energy meters vs other
    // gear (DG sets, ACDB). Trackso doesn't expose a clean device-type field.
    const classify = (name: string): string => {
      const n = name.toLowerCase();
      if (n.includes('mfm') || n.includes('meter')) return 'METER';
      if (n.includes('acdb') || n.includes(' dg ') || n.startsWith('dg ') || n.includes('generator')) {
        return 'OTHER';
      }
      if (n.includes('solis') || n.includes('inverter') || /\d+\s*kw/.test(n)) return 'INVERTER';
      return 'OTHER';
    };

    // Trackso unit status codes: 1 active, 2 inactive, 3 on-error, 0 unconfigured
    const mapStatus = (code: number): string => {
      switch (code) {
        case 1:
          return 'ACTIVE';
        case 3:
          return 'ERROR';
        case 2:
          return 'INACTIVE';
        default:
          return 'UNKNOWN';
      }
    };

    // The units endpoint ignores the siteKeys filter and returns every unit on
    // the account, so filter by each unit's own site_key. Also skip roll-up
    // "Summary" pseudo-units.
    const realUnits = elements.filter(
      (u) =>
        u.site_key === siteKey &&
        typeof u.name === 'string' &&
        !u.name.toLowerCase().startsWith('summary'),
    );

    // 2. One bulk telemetry call for all units
    const now = Date.now();
    const startOfDay = new Date(new Date().setHours(0, 0, 0, 0)).getTime();
    const params = [
      'Output Active Power',
      'Daily Energy',
      'Total Energy',
      'AC Voltage Phase AN',
      'AC Voltage Phase BN',
      'AC Voltage Phase CN',
      'AC Current Phase A',
      'AC Current Phase B',
      'AC Current Phase C',
      'AC Frequency',
    ];
    const unitParameterList: Record<string, string[]> = {};
    for (const u of realUnits) {
      unitParameterList[u.unit_key] = params;
    }

    const liveByUnit: Record<
      string,
      { power: number; energy: number; total: number; voltage: number; current: number; frequency: number }
    > = {};
    if (Object.keys(unitParameterList).length > 0) {
      const dataRes = await fetch(`${this.baseUrl}/dataquery/unit/latest_data`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          unitParameterList,
          validateParameterPresence: true,
          startTime: startOfDay,
          endTime: now,
          suppressErrors: true,
        }),
      });
      if (dataRes.ok) {
        const dataJson = await dataRes.json();
        const groups: any[] = dataJson.result?.result ?? [];
        for (const g of groups) {
          const find = (name: string): number =>
            g.data?.find((p: any) => p.parameter_name === name)?.value ?? 0;
          // Average the phase voltages that are actually reporting (>0)
          const phaseV = [
            find('AC Voltage Phase AN'),
            find('AC Voltage Phase BN'),
            find('AC Voltage Phase CN'),
          ].filter((v) => v > 0);
          const avgV = phaseV.length ? phaseV.reduce((a, b) => a + b, 0) / phaseV.length : 0;
          const sumA =
            find('AC Current Phase A') + find('AC Current Phase B') + find('AC Current Phase C');
          liveByUnit[g.unit_key] = {
            power: find('Output Active Power'),
            energy: find('Daily Energy'),
            // Trackso reports the unit counter in MWh.
            total: find('Total Energy') * 1000,
            voltage: avgV,
            current: sumA,
            frequency: find('AC Frequency'),
          };
        }
      }
    }

    return realUnits.map((u) => ({
      id: u.unit_key,
      name: u.name,
      type: classify(u.name),
      status: mapStatus(u.status),
      capacity: u.capacity ?? u.ac_capacity ?? u.dc_capacity ?? null,
      activePowerKw: parseFloat((liveByUnit[u.unit_key]?.power ?? 0).toFixed(2)),
      dailyEnergyKwh: parseFloat((liveByUnit[u.unit_key]?.energy ?? 0).toFixed(1)),
      totalEnergyKwh: parseFloat((liveByUnit[u.unit_key]?.total ?? 0).toFixed(1)),
      acVoltage: parseFloat((liveByUnit[u.unit_key]?.voltage ?? 0).toFixed(1)),
      acCurrent: parseFloat((liveByUnit[u.unit_key]?.current ?? 0).toFixed(1)),
      acFrequency: parseFloat((liveByUnit[u.unit_key]?.frequency ?? 0).toFixed(2)),
    }));
  }

  /**
   * Energy generated (kWh) over day / week / month / year, summed across all
   * configured sites. Uses Trackso's cumulative "Total Energy" (MWh) counter:
   * period energy = Total(now) − Total(period start).
   */
  async getPeriodYields(
    onlySiteKeys: string[] | null = null,
  ): Promise<{ day: number; week: number; month: number; year: number }> {
    // Restrict to the caller's accessible sites when provided.
    if (onlySiteKeys !== null && onlySiteKeys.length === 0) {
      return { day: 0, week: 0, month: 0, year: 0 };
    }
    const authToken = await this.login();
    const headers = {
      'content-type': 'application/json;charset=UTF-8',
      'x-auth-token': authToken,
      'authorization': authToken,
    };
    const keys = onlySiteKeys ?? this.siteKeys;

    // Total Energy (MWh) as of a given instant, summed across sites.
    const totalAt = async (endMs: number): Promise<number> => {
      const siteParameterList: Record<string, string[]> = {};
      for (const k of keys) siteParameterList[k] = ['Total Energy'];
      const res = await fetch(`${this.baseUrl}/dataquery/site/latest_data`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          siteParameterList,
          validateParameterPresence: true,
          startTime: endMs - 2 * 24 * 60 * 60 * 1000, // 2-day lookback window
          endTime: endMs,
          suppressErrors: true,
        }),
      });
      if (!res.ok) return 0;
      const json = await res.json();
      const groups: any[] = json.result?.result ?? [];
      let sum = 0;
      for (const g of groups) {
        const v = g.data?.find((p: any) => p.parameter_name === 'Total Energy')?.value ?? 0;
        sum += v;
      }
      return sum; // MWh
    };

    // Daily Energy (kWh today), summed across sites.
    const dayYield = async (): Promise<number> => {
      const siteParameterList: Record<string, string[]> = {};
      for (const k of keys) siteParameterList[k] = ['Daily Energy'];
      const startOfDay = new Date(new Date().setHours(0, 0, 0, 0)).getTime();
      const res = await fetch(`${this.baseUrl}/dataquery/site/latest_data`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          siteParameterList,
          validateParameterPresence: true,
          startTime: startOfDay,
          endTime: Date.now(),
          suppressErrors: true,
        }),
      });
      if (!res.ok) return 0;
      const json = await res.json();
      const groups: any[] = json.result?.result ?? [];
      let sum = 0;
      for (const g of groups) {
        sum += g.data?.find((p: any) => p.parameter_name === 'Daily Energy')?.value ?? 0;
      }
      return sum; // kWh
    };

    const now = Date.now();
    const DAY = 24 * 60 * 60 * 1000;
    const [day, totalNow, totalWeek, totalMonth, totalYear] = await Promise.all([
      dayYield(),
      totalAt(now),
      totalAt(now - 7 * DAY),
      totalAt(now - 30 * DAY),
      totalAt(now - 365 * DAY),
    ]);

    // Convert MWh deltas → kWh; guard against missing historical data (0).
    const delta = (past: number) =>
      past > 0 && totalNow >= past ? parseFloat(((totalNow - past) * 1000).toFixed(1)) : 0;

    // If a site is younger than a year, there's no reading from 365 days ago,
    // so the year's generation is its whole lifetime total so far.
    const year = totalYear > 0 ? delta(totalYear) : parseFloat((totalNow * 1000).toFixed(1));

    return {
      day: parseFloat(day.toFixed(1)),
      week: delta(totalWeek),
      month: delta(totalMonth),
      year,
    };
  }

  /** Live open alarms + per-site alarm count breakdown, straight from Trackso. */
  async getOpenAlarms(
    onlySiteKeys: string[] | null = null,
  ): Promise<{ counts: unknown[]; alarms: unknown[] }> {
    if (onlySiteKeys !== null && onlySiteKeys.length === 0) {
      return { counts: [], alarms: [] };
    }
    const authToken = await this.login();
    const headers = {
      'content-type': 'application/json;charset=UTF-8',
      'x-auth-token': authToken,
      'authorization': authToken
    };
    const keys = onlySiteKeys ?? this.siteKeys;
    const siteKeyQuery = keys.map((k) => `siteKeys=${k}`).join('&');
    const [countRes, listRes] = await Promise.all([
      fetch(`${this.baseUrl}/dataquery/alarmCount?${siteKeyQuery}`, { headers }),
      fetch(`${this.baseUrl}/alarms?${siteKeyQuery}`, { headers }),
    ]);
    const countData = countRes.ok ? await countRes.json() : null;
    const listData = listRes.ok ? await listRes.json() : null;
    return {
      counts: Array.isArray(countData?.result) ? countData.result : [],
      alarms: Array.isArray(listData) ? listData : [],
    };
  }

  async generateSiteReport(
    plantId: string,
    frequency: ReportFrequency,
    dateMs: number,
  ): Promise<{ buffer: Buffer; filename: string }> {
    const siteKey = await this.resolveSiteKey(plantId);
    const { from, to } = this.computeRange(frequency, dateMs);
    const authToken = await this.login();

    this.logger.log(`Generating ${frequency} Trackso report for site ${siteKey} (${new Date(from).toISOString()} - ${new Date(to).toISOString()})`);

    const res = await fetch(`${this.baseUrl}/reports/generateSiteReport`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json;charset=UTF-8',
        'x-auth-token': authToken,
        'authorization': authToken
      },
      body: JSON.stringify({
        reportType: 'SITE_ANALYSIS',
        reportFrequency: frequency,
        siteKeys: [siteKey],
        from,
        to
      })
    });

    const contentType = res.headers.get('content-type') ?? '';
    if (!res.ok || contentType.includes('application/json')) {
      // Trackso returns JSON (often 400 with NoDataException) instead of a file on failure
      let message = `Trackso report request failed with status ${res.status}`;
      try {
        const err = await res.json();
        const detail = err?.errors?.[0]?.message;
        if (detail) message = detail;
      } catch { /* keep generic message */ }
      throw new BadRequestException(message);
    }

    const buffer = Buffer.from(await res.arrayBuffer());
    const dateLabel = new Date(from + IST_OFFSET_MS).toISOString().slice(0, 10);
    const filename = `enercore-report-${frequency.toLowerCase()}-${dateLabel}.xlsx`;
    return { buffer, filename };
  }
}
