import { PlantEntity } from './plant.entity';
import { PanelEntity } from './panel.entity';
export interface IPlantRepository {
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
