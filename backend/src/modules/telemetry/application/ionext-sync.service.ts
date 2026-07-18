import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { IoNextService, ProviderDevice } from './ionext.service';
import { TracksoPlantMetrics } from './trackso-sync.service';
import { istDay } from '../../../common/util/ist-day';
import { withJobLock } from '../../../common/util/job-lock';
import { DeviceEnergyRecorder } from './device-energy.recorder';

/** Prefix that namespaces an IO.Next plant in the shared dashboard cache. */
export const IONEXT_KEY_PREFIX = 'IN:';

export function ionextDashboardKey(externalKey: string): string {
  return `${IONEXT_KEY_PREFIX}${externalKey}`;
}

/**
 * Polls IO.Next for every IONEXT plant every 2 minutes and keeps the results
 * in memory, mirroring TracksoSyncService so the dashboard can merge both
 * providers transparently.
 */
@Injectable()
export class IoNextSyncService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(IoNextSyncService.name);
  private interval?: NodeJS.Timeout;

  private devicesByPlantId: Record<string, ProviderDevice[]> = {};
  private dashboardPlants: Record<string, TracksoPlantMetrics> = {};

  constructor(
    private readonly prisma: PrismaService,
    private readonly ioNext: IoNextService,
    private readonly deviceEnergy: DeviceEnergyRecorder,
  ) {}

  onModuleInit() {
    this.logger.log('IO.Next Sync Service initialized.');
    this.sync().catch((err) => this.logger.error('Initial IO.Next sync failed:', err));
    this.interval = setInterval(() => {
      this.sync().catch((err) => this.logger.error('Scheduled IO.Next sync failed:', err));
    }, 120000);
  }

  onModuleDestroy() {
    if (this.interval) clearInterval(this.interval);
  }

  private async sync() {
    await withJobLock(this.prisma, 'ionext-sync', () => this.doSync());
  }

  private async doSync() {
    const plants = await this.prisma.plant.findMany({
      where: { dataSource: 'IONEXT', externalKey: { not: null } },
    });
    for (const plant of plants) {
      const key = plant.externalKey as string;
      try {
        const [devices, summary] = await Promise.all([
          this.ioNext.getDevices(key),
          this.ioNext.getSummary(key),
        ]);
        this.devicesByPlantId[plant.id] = devices;

        // When the reading is stale, live power is 0 and status Inactive, but
        // the plant did generate earlier today — show that from our last saved
        // snapshot rather than 0, so "today" doesn't collapse when the logger
        // blinks offline.
        let dashDaily = summary.dailyEnergy;
        let dashTotal = summary.totalEnergy;
        if (!summary.fresh) {
          const today = await this.prisma.dailyEnergy.findUnique({
            where: { plantId_day: { plantId: plant.id, day: istDay(Date.now()) } },
            select: { energyKwh: true, lifetimeMwh: true },
          });
          dashDaily = today?.energyKwh ?? 0;
          dashTotal = today?.lifetimeMwh ?? summary.totalEnergy;
        }
        this.dashboardPlants[ionextDashboardKey(key)] = {
          siteName: plant.name,
          livePower: summary.livePower,
          dailyEnergy: dashDaily,
          totalEnergy: dashTotal,
          specificYield: plant.peakCapacity > 0
            ? parseFloat((dashDaily / plant.peakCapacity).toFixed(2))
            : 0,
          cuf: summary.cuf,
          status: summary.status,
        };
        // A stale reading (datalogger offline) must not be persisted: writing
        // it would draw a flat line of old values on the charts and, worse,
        // overwrite today's real energy snapshot that billing reads. Keep the
        // last-known-good rows instead and wait for the logger to come back.
        if (!summary.fresh) continue;

        await this.deviceEnergy.record(plant.id, devices);

        // One telemetry row per inverter so the plant's power/voltage charts
        // build up over time. IO.Next reports at inverter level, so these rows
        // carry no panelId; series queries group by plantId.
        const inverters = devices.filter((d) => d.type === 'INVERTER');
        if (inverters.length > 0) {
          const timestamp = new Date();
          await this.prisma.telemetry.createMany({
            data: inverters.map((d) => ({
              plantId: plant.id,
              voltage: d.acVoltage,
              current: d.acCurrent,
              temperature: 0, // IO.Next exposes no device temperature
              generation: d.activePowerKw * 1000, // kW → W, matching Trackso rows
              timestamp,
            })),
          });
        }

        // Snapshot today's energy so historical week/month/year can later be
        // served from our own DB (IO.Next itself keeps no history).
        const day = istDay(Date.now());
        await this.prisma.dailyEnergy.upsert({
          where: { plantId_day: { plantId: plant.id, day } },
          update: { energyKwh: summary.dailyEnergy, lifetimeMwh: summary.totalEnergy },
          create: { plantId: plant.id, day, energyKwh: summary.dailyEnergy, lifetimeMwh: summary.totalEnergy },
        });
      } catch (err) {
        this.logger.error(`IO.Next sync failed for plant ${plant.name}:`, err);
      }
    }
  }

  /** Dashboard metrics for every IONEXT plant, keyed by `IN:<externalKey>`. */
  getDashboardPlants(): Record<string, TracksoPlantMetrics> {
    return this.dashboardPlants;
  }

  /** Cached devices for a plant; falls back to a live fetch on a cold cache. */
  async getDevices(plantId: string, externalKey: string): Promise<ProviderDevice[]> {
    const cached = this.devicesByPlantId[plantId];
    if (cached) return cached;
    const devices = await this.ioNext.getDevices(externalKey);
    this.devicesByPlantId[plantId] = devices;
    return devices;
  }

  /** IONEXT plants in scope for the given dashboard keys (null = all). */
  private async scopedPlantIds(allowedKeys: string[] | null): Promise<string[]> {
    const plants = await this.prisma.plant.findMany({
      where: { dataSource: 'IONEXT', externalKey: { not: null } },
      select: { id: true, externalKey: true },
    });
    return plants
      .filter((p) => !allowedKeys || allowedKeys.includes(ionextDashboardKey(p.externalKey as string)))
      .map((p) => p.id);
  }

  /**
   * Period-yield contribution across the given dashboard keys (or all IONEXT
   * plants when null), summed from the daily snapshots we persist. Real history
   * builds up over time; days before the first snapshot simply aren't counted.
   */
  async getPeriodContribution(
    allowedKeys: string[] | null,
  ): Promise<{ day: number; week: number; month: number; year: number }> {
    const ids = await this.scopedPlantIds(allowedKeys);
    if (ids.length === 0) return { day: 0, week: 0, month: 0, year: 0 };

    const now = Date.now();
    const today = istDay(now);
    const weekStart = istDay(now - 6 * 24 * 60 * 60 * 1000); // last 7 days incl. today
    const yearPrefix = today.slice(0, 4);
    const monthPrefix = today.slice(0, 7);

    const rows = await this.prisma.dailyEnergy.findMany({
      where: { plantId: { in: ids }, day: { startsWith: yearPrefix } },
      select: { day: true, energyKwh: true },
    });

    let day = 0;
    let week = 0;
    let month = 0;
    let year = 0;
    for (const r of rows) {
      year += r.energyKwh;
      if (r.day === today) day += r.energyKwh;
      if (r.day >= weekStart) week += r.energyKwh;
      if (r.day.startsWith(monthPrefix)) month += r.energyKwh;
    }
    return {
      day: parseFloat(day.toFixed(1)),
      week: parseFloat(week.toFixed(1)),
      month: parseFloat(month.toFixed(1)),
      year: parseFloat(year.toFixed(1)),
    };
  }
}
