import { Inject, Injectable } from '@nestjs/common';
import { ITelemetryRepository, TelemetrySeriesPoint } from '../domain/telemetry.repository.interface';
import { TelemetryEntity } from '../domain/telemetry.entity';
import { TracksoSyncService, TracksoDashboardCache } from './trackso-sync.service';

@Injectable()
export class TelemetryService {
  constructor(
    @Inject('ITelemetryRepository')
    private readonly telemetryRepository: ITelemetryRepository,
    private readonly tracksoSync: TracksoSyncService,
  ) {}

  async logTelemetry(dto: Partial<TelemetryEntity>): Promise<TelemetryEntity> {
    return this.telemetryRepository.create(dto);
  }

  async findByPlant(plantId: string, limit?: number): Promise<TelemetryEntity[]> {
    return this.telemetryRepository.findByPlantId(plantId, limit);
  }

  async findLatestByPlant(plantId: string): Promise<TelemetryEntity[]> {
    return this.telemetryRepository.findLatestByPlantId(plantId);
  }

  /**
   * Dashboard aggregates. When `allowedSiteKeys` is provided, restrict the
   * result to those sites and recompute totals so a user only ever sees data
   * for the plants they can access.
   */
  getDashboardStats(allowedSiteKeys: string[] | null = null): TracksoDashboardCache {
    const cache = this.tracksoSync.getDashboardCache();
    if (allowedSiteKeys === null) return cache;

    const allowed = new Set(allowedSiteKeys);
    const plants: TracksoDashboardCache['plants'] = {};
    let totalPower = 0;
    let todayYield = 0;
    let lifetimeYield = 0;
    let cufSum = 0;
    let cufCount = 0;
    const allowedNames: string[] = [];
    for (const [key, p] of Object.entries(cache.plants)) {
      if (!allowed.has(key)) continue;
      plants[key] = p;
      allowedNames.push(p.siteName);
      totalPower += p.livePower;
      todayYield += p.dailyEnergy;
      lifetimeYield += p.totalEnergy;
      if (p.cuf > 0) {
        cufSum += p.cuf;
        cufCount++;
      }
    }

    // Keep only alerts about the user's own sites (INFO fallbacks stay).
    const alerts = cache.alerts.filter(
      (a) => a.type === 'INFO' || allowedNames.some((n) => a.location?.includes(n)),
    );

    return {
      totalPower: parseFloat(totalPower.toFixed(1)),
      todayYield: parseFloat(todayYield.toFixed(1)),
      lifetimeYield: parseFloat(lifetimeYield.toFixed(1)),
      performanceRatio: cufCount > 0 ? parseFloat((cufSum / cufCount).toFixed(1)) : cache.performanceRatio,
      plants,
      alerts,
    };
  }

  async getSeriesByPlant(plantId: string, hours: number): Promise<TelemetrySeriesPoint[]> {
    // Aim for ~48 points regardless of window length; sync runs every 2 minutes.
    const bucketSeconds = Math.max(120, Math.round((hours * 3600) / 48));
    return this.telemetryRepository.getSeriesByPlantId(plantId, hours, bucketSeconds);
  }
}
