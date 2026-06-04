import { Inject, Injectable } from '@nestjs/common';
import { ITelemetryRepository } from '../domain/telemetry.repository.interface';
import { TelemetryEntity } from '../domain/telemetry.entity';

@Injectable()
export class TelemetryService {
  constructor(
    @Inject('ITelemetryRepository')
    private readonly telemetryRepository: ITelemetryRepository,
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
}
