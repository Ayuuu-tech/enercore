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
exports.PrismaTelemetryRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../../common/prisma/prisma.service");
const telemetry_entity_1 = require("../domain/telemetry.entity");
let PrismaTelemetryRepository = class PrismaTelemetryRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    mapToEntity(t) {
        return new telemetry_entity_1.TelemetryEntity({
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
    async create(telemetry) {
        const created = await this.prisma.$transaction(async (tx) => {
            const panel = await tx.panel.findUnique({ where: { id: telemetry.panelId } });
            if (!panel) {
                throw new Error(`Panel with ID ${telemetry.panelId} not found`);
            }
            const t = await tx.telemetry.create({
                data: {
                    voltage: telemetry.voltage,
                    current: telemetry.current,
                    temperature: telemetry.temperature,
                    generation: telemetry.generation,
                    panelId: telemetry.panelId,
                    plantId: panel.plantId,
                    timestamp: telemetry.timestamp,
                },
            });
            await tx.panel.update({
                where: { id: telemetry.panelId },
                data: {
                    voltage: telemetry.voltage,
                    current: telemetry.current,
                    temperature: telemetry.temperature,
                    generation: telemetry.generation,
                    lastSync: new Date(),
                },
            });
            return t;
        });
        return this.mapToEntity(created);
    }
    async findByPlantId(plantId, limit) {
        const logs = await this.prisma.telemetry.findMany({
            where: { plantId },
            orderBy: { timestamp: 'desc' },
            take: limit || 100,
        });
        return logs.map(t => this.mapToEntity(t));
    }
    async findLatestByPlantId(plantId) {
        const panels = await this.prisma.panel.findMany({
            where: { plantId },
            include: {
                telemetry: {
                    orderBy: { timestamp: 'desc' },
                    take: 1,
                },
            },
        });
        const latestLogs = [];
        for (const panel of panels) {
            if (panel.telemetry && panel.telemetry.length > 0) {
                latestLogs.push(panel.telemetry[0]);
            }
        }
        return latestLogs.map(l => this.mapToEntity(l));
    }
};
exports.PrismaTelemetryRepository = PrismaTelemetryRepository;
exports.PrismaTelemetryRepository = PrismaTelemetryRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PrismaTelemetryRepository);
//# sourceMappingURL=prisma-telemetry.repository.js.map