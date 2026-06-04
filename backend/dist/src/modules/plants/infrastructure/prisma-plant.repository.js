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
Object.defineProperty(exports, "__esModule", { value: true });
exports.PrismaPlantRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../../common/prisma/prisma.service");
const plant_entity_1 = require("../domain/plant.entity");
const panel_entity_1 = require("../domain/panel.entity");
let PrismaPlantRepository = class PrismaPlantRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    mapPlantToEntity(p) {
        return new plant_entity_1.PlantEntity({
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
    mapPanelToEntity(p) {
        return new panel_entity_1.PanelEntity({
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
    async findById(id) {
        const p = await this.prisma.plant.findUnique({ where: { id } });
        return p ? this.mapPlantToEntity(p) : null;
    }
    async findAll() {
        const plants = await this.prisma.plant.findMany();
        return plants.map(p => this.mapPlantToEntity(p));
    }
    async findAllByOwnerId(ownerId) {
        const plants = await this.prisma.plant.findMany({ where: { ownerId } });
        return plants.map(p => this.mapPlantToEntity(p));
    }
    async create(plant) {
        const created = await this.prisma.plant.create({
            data: {
                name: plant.name,
                location: plant.location,
                peakCapacity: plant.peakCapacity,
                status: plant.status || 'Active',
                ownerId: plant.ownerId,
            },
        });
        return this.mapPlantToEntity(created);
    }
    async update(id, plant) {
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
    async delete(id) {
        await this.prisma.plant.delete({ where: { id } });
        return true;
    }
    async findPanelById(id) {
        const p = await this.prisma.panel.findUnique({ where: { id } });
        return p ? this.mapPanelToEntity(p) : null;
    }
    async findPanelsByPlantId(plantId) {
        const panels = await this.prisma.panel.findMany({ where: { plantId } });
        return panels.map(p => this.mapPanelToEntity(p));
    }
    async createPanel(panel) {
        const created = await this.prisma.panel.create({
            data: {
                row: panel.row,
                column: panel.column,
                status: panel.status || 'HEALTHY',
                voltage: panel.voltage || 0.0,
                current: panel.current || 0.0,
                temperature: panel.temperature || 0.0,
                generation: panel.generation || 0.0,
                plantId: panel.plantId,
            },
        });
        return this.mapPanelToEntity(created);
    }
    async updatePanel(id, panel) {
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
    async deletePanel(id) {
        await this.prisma.panel.delete({ where: { id } });
        return true;
    }
};
exports.PrismaPlantRepository = PrismaPlantRepository;
exports.PrismaPlantRepository = PrismaPlantRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PrismaPlantRepository);
//# sourceMappingURL=prisma-plant.repository.js.map