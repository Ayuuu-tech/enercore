import { PrismaService } from '../../../common/prisma/prisma.service';
import { IPlantRepository } from '../domain/plant.repository.interface';
import { PlantEntity } from '../domain/plant.entity';
import { PanelEntity } from '../domain/panel.entity';
export declare class PrismaPlantRepository implements IPlantRepository {
    private prisma;
    constructor(prisma: PrismaService);
    private mapPlantToEntity;
    private mapPanelToEntity;
    findById(id: string): Promise<PlantEntity | null>;
    findAll(): Promise<PlantEntity[]>;
    findAllByOwnerId(ownerId: string): Promise<PlantEntity[]>;
    create(plant: Partial<PlantEntity>): Promise<PlantEntity>;
    update(id: string, plant: Partial<PlantEntity>): Promise<PlantEntity>;
    delete(id: string): Promise<boolean>;
    findPanelById(id: string): Promise<PanelEntity | null>;
    findPanelsByPlantId(plantId: string): Promise<PanelEntity[]>;
    createPanel(panel: Partial<PanelEntity>): Promise<PanelEntity>;
    updatePanel(id: string, panel: Partial<PanelEntity>): Promise<PanelEntity>;
    deletePanel(id: string): Promise<boolean>;
}
