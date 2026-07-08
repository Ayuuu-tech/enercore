import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { IPlantRepository } from '../domain/plant.repository.interface';
import { PlantEntity } from '../domain/plant.entity';
import { PanelEntity } from '../domain/panel.entity';

@Injectable()
export class PlantsService {
  constructor(
    @Inject('IPlantRepository')
    private readonly plantRepository: IPlantRepository,
  ) {}

  async findById(id: string): Promise<PlantEntity> {
    const plant = await this.plantRepository.findById(id);
    if (!plant) {
      throw new NotFoundException(`Plant with ID ${id} not found`);
    }
    return plant;
  }

  async findAll(): Promise<PlantEntity[]> {
    return this.plantRepository.findAll();
  }

  async findAllByOwner(ownerId: string): Promise<PlantEntity[]> {
    return this.plantRepository.findAllByOwnerId(ownerId);
  }

  async findByIds(ids: string[]): Promise<PlantEntity[]> {
    return this.plantRepository.findByIds(ids);
  }

  async create(dto: Partial<PlantEntity>): Promise<PlantEntity> {
    return this.plantRepository.create(dto);
  }

  async update(id: string, dto: Partial<PlantEntity>): Promise<PlantEntity> {
    await this.findById(id);
    return this.plantRepository.update(id, dto);
  }

  async delete(id: string): Promise<boolean> {
    await this.findById(id);
    return this.plantRepository.delete(id);
  }

  // Panels
  async findPanelsByPlant(plantId: string): Promise<PanelEntity[]> {
    await this.findById(plantId);
    return this.plantRepository.findPanelsByPlantId(plantId);
  }

  async createPanel(plantId: string, dto: Partial<PanelEntity>): Promise<PanelEntity> {
    await this.findById(plantId);
    return this.plantRepository.createPanel({ ...dto, plantId });
  }

  async updatePanel(id: string, dto: Partial<PanelEntity>): Promise<PanelEntity> {
    const panel = await this.plantRepository.findPanelById(id);
    if (!panel) {
      throw new NotFoundException(`Panel with ID ${id} not found`);
    }
    return this.plantRepository.updatePanel(id, dto);
  }

  async deletePanel(id: string): Promise<boolean> {
    const panel = await this.plantRepository.findPanelById(id);
    if (!panel) {
      throw new NotFoundException(`Panel with ID ${id} not found`);
    }
    return this.plantRepository.deletePanel(id);
  }
}
