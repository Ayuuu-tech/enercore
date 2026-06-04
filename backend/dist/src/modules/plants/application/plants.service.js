"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PlantsService = void 0;
const common_1 = require("@nestjs/common");
let PlantsService = class PlantsService {
    plantRepository;
    constructor(plantRepository) {
        this.plantRepository = plantRepository;
    }
    async findById(id) {
        const plant = await this.plantRepository.findById(id);
        if (!plant) {
            throw new common_1.NotFoundException(`Plant with ID ${id} not found`);
        }
        return plant;
    }
    async findAll() {
        return this.plantRepository.findAll();
    }
    async findAllByOwner(ownerId) {
        return this.plantRepository.findAllByOwnerId(ownerId);
    }
    async create(dto) {
        return this.plantRepository.create(dto);
    }
    async update(id, dto) {
        await this.findById(id);
        return this.plantRepository.update(id, dto);
    }
    async delete(id) {
        await this.findById(id);
        return this.plantRepository.delete(id);
    }
    async findPanelsByPlant(plantId) {
        await this.findById(plantId);
        return this.plantRepository.findPanelsByPlantId(plantId);
    }
    async createPanel(plantId, dto) {
        await this.findById(plantId);
        return this.plantRepository.createPanel({ ...dto, plantId });
    }
    async updatePanel(id, dto) {
        const panel = await this.plantRepository.findPanelById(id);
        if (!panel) {
            throw new common_1.NotFoundException(`Panel with ID ${id} not found`);
        }
        return this.plantRepository.updatePanel(id, dto);
    }
    async deletePanel(id) {
        const panel = await this.plantRepository.findPanelById(id);
        if (!panel) {
            throw new common_1.NotFoundException(`Panel with ID ${id} not found`);
        }
        return this.plantRepository.deletePanel(id);
    }
};
exports.PlantsService = PlantsService;
exports.PlantsService = PlantsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, common_1.Inject)('IPlantRepository')),
    __metadata("design:paramtypes", [Object])
], PlantsService);
//# sourceMappingURL=plants.service.js.map