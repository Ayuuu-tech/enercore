import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as ExcelJS from 'exceljs';
import { PrismaService } from '../../../common/prisma/prisma.service';

const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;
const istDay = (ms: number) => new Date(ms + IST_OFFSET_MS).toISOString().slice(0, 10);

/** Same device shape the Trackso provider returns, so the app is source-agnostic. */
export interface ProviderDevice {
  id: string;
  name: string;
  type: string; // INVERTER | METER | OTHER
  status: string; // ACTIVE | ERROR | INACTIVE | UNKNOWN
  capacity: number | null;
  activePowerKw: number;
  dailyEnergyKwh: number;
  /** Cumulative generation counter (kWh); 0 when the provider doesn't expose one. */
  totalEnergyKwh: number;
  acVoltage: number;
  acCurrent: number;
  acFrequency: number;
}

export interface ProviderSummary {
  livePower: number; // kW
  dailyEnergy: number; // kWh
  totalEnergy: number; // MWh
  cuf: number; // %
  status: string;
  /** Whether the reading is current (datalogger online and recently stamped). */
  fresh: boolean;
}

/**
 * Client for IO.Next (ionest.cloud). The live values come from a datalogger
 * proxied through the portal: login → dashboard_widgets (to read the logger
 * connection) → color_widget_value (the actual readings).
 */
@Injectable()
export class IoNextService {
  private readonly logger = new Logger(IoNextService.name);
  private token: string | null = null;
  private tokenExpiry = 0;
  private companyPk: number | null = null;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  private get baseUrl(): string {
    return this.config.get<string>('IONEXT_BASE_URL') ?? 'https://backend2.ionest.cloud/api';
  }

  private async login(): Promise<{ token: string; companyPk: number }> {
    if (this.token && Date.now() < this.tokenExpiry && this.companyPk != null) {
      return { token: this.token, companyPk: this.companyPk };
    }
    const res = await fetch(`${this.baseUrl}/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        username: this.config.get<string>('IONEXT_USERNAME'),
        password: this.config.get<string>('IONEXT_PASSWORD'),
      }),
    });
    if (!res.ok) throw new Error(`IO.Next login failed (${res.status})`);
    const data = await res.json();
    const token = data.user?.token;
    const companyPk = data.user?.company_name_pk ?? data.user?.all_companies?.[0];
    if (!token || companyPk == null) throw new Error('IO.Next login missing token/company');
    this.token = token;
    this.companyPk = companyPk;
    this.tokenExpiry = Date.now() + 50 * 60 * 1000; // ~50 min
    return { token, companyPk };
  }

  private async post(path: string, body: unknown): Promise<any> {
    const { token } = await this.login();
    const res = await fetch(`${this.baseUrl}/${path}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new BadRequestException(`IO.Next ${path} failed (${res.status})`);
    return res.json();
  }

  // Per-plant meter + parameter catalogue (device pk and each parameter's pk).
  // It's configuration, not telemetry, so cache it for an hour.
  private meterCatalogue = new Map<
    string,
    { expires: number; meters: { pk: number; label: string; params: Record<string, number> }[] }
  >();

  private async getMeters(externalKey: string) {
    const cached = this.meterCatalogue.get(externalKey);
    if (cached && Date.now() < cached.expires) return cached.meters;

    const form = await this.post('by_device_form', { clients: [Number(externalKey)] });
    const meters = ((form.meters ?? []) as any[]).map((m) => ({
      pk: m.pk as number,
      label: m.label as string,
      params: Object.fromEntries(
        ((m.meter_parameter ?? []) as any[]).map((p) => [p.name as string, p.pk as number]),
      ) as Record<string, number>,
    }));
    this.meterCatalogue.set(externalKey, { expires: Date.now() + 60 * 60 * 1000, meters });
    return meters;
  }

  /** Today's date as the portal wants it: DD/MM/YYYY in IST. */
  private istDateSlash(ms: number): string {
    const [y, m, d] = istDay(ms).split('-');
    return `${d}/${m}/${y}`;
  }

  /**
   * Latest reading today for every device, via the portal's own chart backend
   * (`by_device_form_submit`).
   *
   * We used to read the datalogger proxy (`color_widget_value`) directly, but
   * that stalls the moment the logger drops — it replays a days-old file that
   * looks live. This endpoint is served from IO.Next's database instead, so it
   * stays fresh through a logger blip and matches what their portal shows.
   */
  private async fetchLiveData(plantPk: string): Promise<{
    fresh: boolean;
    devices: Record<string, Record<string, number>>;
  }> {
    const meters = await this.getMeters(plantPk);
    if (meters.length === 0) return { fresh: false, devices: {} };

    const wanted = [
      'Active_Pow', 'Total_Pow', 'Energy_Today', 'Tot_Energy',
      'Volt_R', 'Volt_Y', 'Volt_B', 'Curr_R', 'Curr_Y', 'Curr_B', 'Freq',
    ];
    const meterPks: number[] = [];
    const paramPks: number[] = [];
    for (const m of meters) {
      meterPks.push(m.pk);
      for (const name of wanted) if (m.params[name] != null) paramPks.push(m.params[name]);
    }

    const today = this.istDateSlash(Date.now());
    const res = await this.post('by_device_form_submit', {
      meters: meterPks,
      parameters: paramPks,
      date_range: `${today}-${today}`,
      frequency: '1440', // daily bucket
      operation: 'Last Value', // the most recent reading in the bucket
      duration1: '00:00',
      duration2: '00:00',
    });

    const csv: any[][] = res.csv_data ?? [];
    const devices: Record<string, Record<string, number>> = {};
    if (csv.length < 2) return { fresh: false, devices };

    const headers = csv[0].map(String); // "Active_Pow-Inverter_1-Hella India"
    const row = csv[csv.length - 1]; // today's row
    for (let i = 1; i < headers.length; i++) {
      const match = /^(.+?)-(.+?)-/.exec(headers[i]);
      if (!match) continue;
      const [, param, device] = match;
      const v = Number(row[i]);
      if (!Number.isFinite(v)) continue;
      (devices[device] ??= {})[param] = v;
    }
    // If the plant genuinely hasn't reported today, there are no device columns.
    return { fresh: Object.keys(devices).length > 0, devices };
  }

  private num(v: unknown): number {
    const n = parseFloat(String(v ?? '0'));
    return Number.isFinite(n) ? n : 0;
  }

  private classify(name: string): string {
    const n = name.toLowerCase();
    if (n.includes('inverter') || n.startsWith('inv')) return 'INVERTER';
    if (n.includes('dg') || n.includes('kva') || n.includes('gen')) return 'OTHER';
    if (n.includes('meter') || n.includes('mfm')) return 'METER';
    return 'OTHER';
  }

  private capacityFromName(name: string): number | null {
    const m = name.match(/(\d+)\s*kva/i) || name.match(/(\d+)\s*kw/i);
    return m ? parseInt(m[1], 10) : null;
  }

  async getDevices(plantPk: string): Promise<ProviderDevice[]> {
    const { fresh, devices } = await this.fetchLiveData(plantPk);
    const out: ProviderDevice[] = [];
    for (const [name, v] of Object.entries(devices)) {
      const type = this.classify(name);
      const phasesV = [this.num(v.Volt_R), this.num(v.Volt_Y), this.num(v.Volt_B)].filter((x) => x > 0);
      const avgV = phasesV.length ? phasesV.reduce((a, b) => a + b, 0) / phasesV.length : 0;
      const sumA = this.num(v.Curr_R) + this.num(v.Curr_Y) + this.num(v.Curr_B);
      // Inverters expose Active_Pow / Energy_Today; DG meters do not.
      const power = type === 'INVERTER' ? this.num(v.Active_Pow) : this.num(v.Total_Pow);
      out.push({
        id: `${plantPk}:${name}`,
        name,
        type,
        // When the reading is stale, the device is offline — don't show old
        // power/voltage as if it were current.
        status: fresh && (power > 0 || avgV > 0) ? 'ACTIVE' : 'INACTIVE',
        capacity: this.capacityFromName(name),
        activePowerKw: fresh ? parseFloat(power.toFixed(2)) : 0,
        dailyEnergyKwh: fresh ? parseFloat(this.num(v.Energy_Today).toFixed(1)) : 0,
        // The lifetime counter is still the last-known-good value even when
        // offline; billing reads it as a cumulative meter, so keep it.
        totalEnergyKwh: parseFloat(this.num(v.Tot_Energy).toFixed(1)),
        acVoltage: fresh ? parseFloat(avgV.toFixed(1)) : 0,
        acCurrent: fresh ? parseFloat(sumA.toFixed(1)) : 0,
        acFrequency: fresh ? parseFloat(this.num(v.Freq).toFixed(2)) : 0,
      });
    }
    return out;
  }

  /**
   * IO.Next exposes only live readings and a lifetime counter (no historical
   * period data), so the report is a labelled live snapshot of the plant:
   * a summary sheet plus a per-device readings sheet.
   */
  async generateReport(
    plantPk: string,
    plantId: string,
    plantName: string,
    peakCapacity: number,
    frequency: string,
  ): Promise<{ buffer: Buffer; filename: string }> {
    const [devices, summary] = await Promise.all([
      this.getDevices(plantPk),
      this.getSummary(plantPk),
    ]);
    const now = new Date();

    // Historical breakdown for the requested period, from our daily snapshots.
    const today = istDay(now.getTime());
    let periodFrom = today;
    if (frequency === 'WEEKLY') periodFrom = istDay(now.getTime() - 6 * 24 * 60 * 60 * 1000);
    else if (frequency === 'MONTHLY') periodFrom = today.slice(0, 7) + '-01';
    else if (frequency === 'YEARLY') periodFrom = today.slice(0, 4) + '-01-01';
    const history =
      frequency === 'DAILY'
        ? []
        : await this.prisma.dailyEnergy.findMany({
            where: { plantId, day: { gte: periodFrom, lte: today } },
            orderBy: { day: 'asc' },
            select: { day: true, energyKwh: true },
          });
    const periodTotal = history.reduce((s, r) => s + r.energyKwh, 0);
    const wb = new ExcelJS.Workbook();
    wb.creator = 'Enercore';
    wb.created = now;

    const sum = wb.addWorksheet('Summary');
    sum.columns = [
      { header: 'Metric', key: 'k', width: 28 },
      { header: 'Value', key: 'v', width: 32 },
    ];
    sum.getRow(1).font = { bold: true };
    sum.addRows([
      { k: 'Plant', v: plantName },
      { k: 'Data Source', v: 'IO.Next' },
      { k: 'Report Type', v: frequency === 'DAILY' ? 'DAILY (live snapshot)' : frequency },
      { k: 'Generated At', v: now.toLocaleString('en-IN') },
      { k: 'Peak Capacity (kWp)', v: peakCapacity },
      { k: 'Live Power (kW)', v: summary.livePower },
      { k: "Today's Energy (kWh)", v: summary.dailyEnergy },
      { k: 'Lifetime Energy (MWh)', v: summary.totalEnergy },
      { k: 'Plant Status', v: summary.status },
    ]);
    if (frequency !== 'DAILY') {
      sum.addRow({ k: `${frequency} Energy (kWh)`, v: parseFloat(periodTotal.toFixed(1)) });
      sum.addRow({ k: 'Days Recorded', v: history.length });
    }
    sum.addRow({
      k: 'Note',
      v:
        frequency === 'DAILY'
          ? 'Live snapshot of the plant at generation time.'
          : 'Period totals are aggregated from daily snapshots recorded by Enercore.',
    });

    const sheet = wb.addWorksheet('Devices');
    sheet.columns = [
      { header: 'Device', key: 'name', width: 18 },
      { header: 'Type', key: 'type', width: 12 },
      { header: 'Status', key: 'status', width: 12 },
      { header: 'Capacity', key: 'capacity', width: 12 },
      { header: 'Active Power (kW)', key: 'power', width: 18 },
      { header: "Today's Energy (kWh)", key: 'energy', width: 20 },
      { header: 'Voltage (V)', key: 'voltage', width: 14 },
      { header: 'Current (A)', key: 'current', width: 14 },
      { header: 'Frequency (Hz)', key: 'freq', width: 15 },
    ];
    sheet.getRow(1).font = { bold: true };
    for (const d of devices) {
      sheet.addRow({
        name: d.name,
        type: d.type,
        status: d.status,
        capacity: d.capacity ?? '—',
        power: d.activePowerKw,
        energy: d.dailyEnergyKwh,
        voltage: d.acVoltage,
        current: d.acCurrent,
        freq: d.acFrequency,
      });
    }

    if (history.length > 0) {
      const hist = wb.addWorksheet('Daily History');
      hist.columns = [
        { header: 'Date', key: 'day', width: 16 },
        { header: 'Energy (kWh)', key: 'energyKwh', width: 16 },
      ];
      hist.getRow(1).font = { bold: true };
      for (const r of history) hist.addRow({ day: r.day, energyKwh: r.energyKwh });
      hist.addRow({ day: 'Total', energyKwh: parseFloat(periodTotal.toFixed(1)) }).font = {
        bold: true,
      };
    }

    const buffer = Buffer.from(await wb.xlsx.writeBuffer());
    const dateLabel = now.toISOString().slice(0, 10);
    const filename = `enercore-report-${frequency.toLowerCase()}-${dateLabel}.xlsx`;
    return { buffer, filename };
  }

  async getSummary(plantPk: string): Promise<ProviderSummary> {
    const { fresh, devices } = await this.fetchLiveData(plantPk);
    let livePower = 0;
    let dailyEnergy = 0;
    let totalEnergyKwh = 0;
    for (const [name, v] of Object.entries(devices)) {
      if (this.classify(name) !== 'INVERTER') continue;
      livePower += this.num(v.Active_Pow);
      dailyEnergy += this.num(v.Energy_Today);
      totalEnergyKwh += this.num(v.Tot_Energy);
    }
    return {
      // Stale readings mean the plant isn't reporting: show no live power and
      // no "today" rather than replaying a days-old file as the current value.
      livePower: fresh ? parseFloat(livePower.toFixed(1)) : 0,
      dailyEnergy: fresh ? parseFloat(dailyEnergy.toFixed(1)) : 0,
      totalEnergy: parseFloat((totalEnergyKwh / 1000).toFixed(1)), // MWh (last known)
      cuf: 0, // IO.Next doesn't expose CUF
      status: fresh ? 'Active' : 'Inactive',
      fresh,
    };
  }
}
