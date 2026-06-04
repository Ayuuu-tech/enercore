import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { ITelemetryRepository } from '../domain/telemetry.repository.interface';
import { TelemetryEntity } from '../domain/telemetry.entity';
import { Telemetry as PrismaTelemetry } from '@prisma/client';

@Injectable()
export class PrismaTelemetryRepository implements ITelemetryRepository {
  constructor(private prisma: PrismaService) {}

  private mapToEntity(t: PrismaTelemetry): TelemetryEntity {
    return new TelemetryEntity({
      id: t.id,
      voltage: t.voltage,
      current: t.current,
      temperature: t.temperature,
      generation: t.generation,
      timestamp: t.timestamp,
      panelId: t.panelId,
      plantId: t.plantId,
    });
  }

  async create(telemetry: Partial<TelemetryEntity>): Promise<TelemetryEntity> {
    const created = await this.prisma.$transaction(async (tx) => {
      const panel = await tx.panel.findUnique({ where: { id: telemetry.panelId } });
      if (!panel) {
        throw new Error(`Panel with ID ${telemetry.panelId} not found`);
      }
      const t = await tx.telemetry.create({
        data: {
          voltage: telemetry.voltage!,
          current: telemetry.current!,
          temperature: telemetry.temperature!,
          generation: telemetry.generation!,
          panelId: telemetry.panelId!,
          plantId: panel.plantId,
          timestamp: telemetry.timestamp,
        },
      });
      await tx.panel.update({
        where: { id: telemetry.panelId },
        data: {
          voltage: telemetry.voltage!,
          current: telemetry.current!,
          temperature: telemetry.temperature!,
          generation: telemetry.generation!,
          lastSync: new Date(),
        },
      });
      return t;
    });
    return this.mapToEntity(created);
  }

  async findByPlantId(plantId: string, limit?: number): Promise<TelemetryEntity[]> {
    const logs = await this.prisma.telemetry.findMany({
      where: { plantId },
      orderBy: { timestamp: 'desc' },
      take: limit || 100,
    });
    return logs.map(t => this.mapToEntity(t));
  }

  async findLatestByPlantId(plantId: string): Promise<TelemetryEntity[]> {
    const panels = await this.prisma.panel.findMany({
      where: { plantId },
      include: {
        telemetry: {
          orderBy: { timestamp: 'desc' },
          take: 1,
        },
      },
    });

    const latestLogs: PrismaTelemetry[] = [];
    for (const panel of panels) {
      if (panel.telemetry && panel.telemetry.length > 0) {
        latestLogs.push(panel.telemetry[0]);
      }
    }

    return latestLogs.map(l => this.mapToEntity(l));
  }
}
