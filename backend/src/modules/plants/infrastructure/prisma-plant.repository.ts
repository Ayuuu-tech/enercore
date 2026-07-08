import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { IPlantRepository } from '../domain/plant.repository.interface';
import { PlantEntity } from '../domain/plant.entity';
import { PanelEntity } from '../domain/panel.entity';
import { Plant as PrismaPlant, Panel as PrismaPanel } from '@prisma/client';

@Injectable()
export class PrismaPlantRepository implements IPlantRepository {
  constructor(private prisma: PrismaService) {}

  private mapPlantToEntity(p: PrismaPlant): PlantEntity {
    return new PlantEntity({
      id: p.id,
      name: p.name,
      location: p.location,
      peakCapacity: p.peakCapacity,
      status: p.status,
      ownerId: p.ownerId,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    });
  }

  private mapPanelToEntity(p: PrismaPanel): PanelEntity {
    return new PanelEntity({
      id: p.id,
      row: p.row,
      column: p.column,
      status: p.status,
      voltage: p.voltage,
      current: p.current,
      temperature: p.temperature,
      generation: p.generation,
      lastSync: p.lastSync,
      plantId: p.plantId,
    });
  }

  async findById(id: string): Promise<PlantEntity | null> {
    const p = await this.prisma.plant.findUnique({ where: { id } });
    return p ? this.mapPlantToEntity(p) : null;
  }

  async findAll(): Promise<PlantEntity[]> {
    const plants = await this.prisma.plant.findMany();
    return plants.map(p => this.mapPlantToEntity(p));
  }

  async findAllByOwnerId(ownerId: string): Promise<PlantEntity[]> {
    const plants = await this.prisma.plant.findMany({ where: { ownerId } });
    return plants.map(p => this.mapPlantToEntity(p));
  }

  async findByIds(ids: string[]): Promise<PlantEntity[]> {
    if (ids.length === 0) return [];
    const plants = await this.prisma.plant.findMany({ where: { id: { in: ids } } });
    return plants.map(p => this.mapPlantToEntity(p));
  }

  async create(plant: Partial<PlantEntity>): Promise<PlantEntity> {
    const created = await this.prisma.plant.create({
      data: {
        name: plant.name!,
        location: plant.location!,
        peakCapacity: plant.peakCapacity!,
        status: plant.status || 'Active',
        ownerId: plant.ownerId!,
      },
    });
    return this.mapPlantToEntity(created);
  }

  async update(id: string, plant: Partial<PlantEntity>): Promise<PlantEntity> {
    const updated = await this.prisma.plant.update({
      where: { id },
      data: {
        name: plant.name,
        location: plant.location,
        peakCapacity: plant.peakCapacity,
        status: plant.status,
      },
    });
    return this.mapPlantToEntity(updated);
  }

  async delete(id: string): Promise<boolean> {
    await this.prisma.plant.delete({ where: { id } });
    return true;
  }

  // Panels
  async findPanelById(id: string): Promise<PanelEntity | null> {
    const p = await this.prisma.panel.findUnique({ where: { id } });
    return p ? this.mapPanelToEntity(p) : null;
  }

  async findPanelsByPlantId(plantId: string): Promise<PanelEntity[]> {
    const panels = await this.prisma.panel.findMany({ where: { plantId } });
    return panels.map(p => this.mapPanelToEntity(p));
  }

  async createPanel(panel: Partial<PanelEntity>): Promise<PanelEntity> {
    const created = await this.prisma.panel.create({
      data: {
        row: panel.row!,
        column: panel.column!,
        status: panel.status || 'HEALTHY',
        voltage: panel.voltage || 0.0,
        current: panel.current || 0.0,
        temperature: panel.temperature || 0.0,
        generation: panel.generation || 0.0,
        plantId: panel.plantId!,
      },
    });
    return this.mapPanelToEntity(created);
  }

  async updatePanel(id: string, panel: Partial<PanelEntity>): Promise<PanelEntity> {
    const updated = await this.prisma.panel.update({
      where: { id },
      data: {
        row: panel.row,
        column: panel.column,
        status: panel.status,
        voltage: panel.voltage,
        current: panel.current,
        temperature: panel.temperature,
        generation: panel.generation,
        lastSync: panel.lastSync,
      },
    });
    return this.mapPanelToEntity(updated);
  }

  async deletePanel(id: string): Promise<boolean> {
    await this.prisma.panel.delete({ where: { id } });
    return true;
  }
}
