import { PrismaService } from '../../../common/prisma/prisma.service';
import { ITelemetryRepository } from '../domain/telemetry.repository.interface';
import { TelemetryEntity } from '../domain/telemetry.entity';
export declare class PrismaTelemetryRepository implements ITelemetryRepository {
    private prisma;
    constructor(prisma: PrismaService);
    private mapToEntity;
    create(telemetry: Partial<TelemetryEntity>): Promise<TelemetryEntity>;
    findByPlantId(plantId: string, limit?: number): Promise<TelemetryEntity[]>;
    findLatestByPlantId(plantId: string): Promise<TelemetryEntity[]>;
}
