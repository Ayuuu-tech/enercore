import { ITelemetryRepository } from '../domain/telemetry.repository.interface';
import { TelemetryEntity } from '../domain/telemetry.entity';
export declare class TelemetryService {
    private readonly telemetryRepository;
    constructor(telemetryRepository: ITelemetryRepository);
    logTelemetry(dto: Partial<TelemetryEntity>): Promise<TelemetryEntity>;
    findByPlant(plantId: string, limit?: number): Promise<TelemetryEntity[]>;
    findLatestByPlant(plantId: string): Promise<TelemetryEntity[]>;
}
