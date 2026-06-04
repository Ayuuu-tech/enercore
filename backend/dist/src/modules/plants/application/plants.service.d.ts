import { IPlantRepository } from '../domain/plant.repository.interface';
import { PlantEntity } from '../domain/plant.entity';
import { PanelEntity } from '../domain/panel.entity';
export declare class PlantsService {
    private readonly plantRepository;
    constructor(plantRepository: IPlantRepository);
    findById(id: string): Promise<PlantEntity>;
    findAll(): Promise<PlantEntity[]>;
    findAllByOwner(ownerId: string): Promise<PlantEntity[]>;
    create(dto: Partial<PlantEntity>): Promise<PlantEntity>;
    update(id: string, dto: Partial<PlantEntity>): Promise<PlantEntity>;
    delete(id: string): Promise<boolean>;
    findPanelsByPlant(plantId: string): Promise<PanelEntity[]>;
    createPanel(plantId: string, dto: Partial<PanelEntity>): Promise<PanelEntity>;
    updatePanel(id: string, dto: Partial<PanelEntity>): Promise<PanelEntity>;
    deletePanel(id: string): Promise<boolean>;
}
