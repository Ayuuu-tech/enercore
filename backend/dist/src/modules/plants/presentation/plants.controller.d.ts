import { PlantsService } from '../application/plants.service';
import { CreatePlantDto } from './dto/create-plant.dto';
import { CreatePanelDto } from './dto/create-panel.dto';
import { UserEntity } from '../../users/domain/user.entity';
export declare class PlantsController {
    private readonly plantsService;
    constructor(plantsService: PlantsService);
    findAll(user: UserEntity): Promise<import("../domain/plant.entity").PlantEntity[]>;
    findOne(id: string, user: UserEntity): Promise<import("../domain/plant.entity").PlantEntity>;
    create(createPlantDto: CreatePlantDto, user: UserEntity): Promise<import("../domain/plant.entity").PlantEntity>;
    update(id: string, dto: Partial<CreatePlantDto>, user: UserEntity): Promise<import("../domain/plant.entity").PlantEntity>;
    remove(id: string, user: UserEntity): Promise<boolean>;
    findPanels(id: string, user: UserEntity): Promise<import("../domain/panel.entity").PanelEntity[]>;
    createPanel(id: string, dto: CreatePanelDto, user: UserEntity): Promise<import("../domain/panel.entity").PanelEntity>;
    updatePanel(panelId: string, dto: Partial<CreatePanelDto> & {
        voltage?: number;
        current?: number;
        temperature?: number;
        generation?: number;
    }, user: UserEntity): Promise<import("../domain/panel.entity").PanelEntity>;
    removePanel(panelId: string, user: UserEntity): Promise<boolean>;
}
