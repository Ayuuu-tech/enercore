import { TelemetryService } from '../application/telemetry.service';
import { CreateTelemetryDto } from './dto/create-telemetry.dto';
export declare class TelemetryController {
    private readonly telemetryService;
    constructor(telemetryService: TelemetryService);
    logTelemetry(dto: CreateTelemetryDto): Promise<import("../domain/telemetry.entity").TelemetryEntity>;
    findByPlant(plantId: string, limit?: string): Promise<import("../domain/telemetry.entity").TelemetryEntity[]>;
    findLatestByPlant(plantId: string): Promise<import("../domain/telemetry.entity").TelemetryEntity[]>;
}
