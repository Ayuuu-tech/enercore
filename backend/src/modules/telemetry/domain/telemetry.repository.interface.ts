import { TelemetryEntity } from './telemetry.entity';

export interface TelemetrySeriesPoint {
  timestamp: Date;
  avgVoltage: number;
  totalCurrent: number;
  avgTemperature: number;
  totalGeneration: number;
}

export interface ITelemetryRepository {
  create(telemetry: Partial<TelemetryEntity>): Promise<TelemetryEntity>;
  findByPlantId(plantId: string, limit?: number): Promise<TelemetryEntity[]>;
  findLatestByPlantId(plantId: string): Promise<TelemetryEntity[]>;
  /** Bucket width is derived from the data actually present in the window. */
  getSeriesByPlantId(plantId: string, hours: number, targetPoints: number): Promise<TelemetrySeriesPoint[]>;
}
