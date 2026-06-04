import { TelemetryEntity } from './telemetry.entity';

export interface ITelemetryRepository {
  create(telemetry: Partial<TelemetryEntity>): Promise<TelemetryEntity>;
  findByPlantId(plantId: string, limit?: number): Promise<TelemetryEntity[]>;
  findLatestByPlantId(plantId: string): Promise<TelemetryEntity[]>;
}
