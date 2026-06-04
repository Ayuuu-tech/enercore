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
exports.PlantsController = void 0;
const common_1 = require("@nestjs/common");
const plants_service_1 = require("../application/plants.service");
const create_plant_dto_1 = require("./dto/create-plant.dto");
const create_panel_dto_1 = require("./dto/create-panel.dto");
const jwt_auth_guard_1 = require("../../../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../../../common/guards/roles.guard");
const current_user_decorator_1 = require("../../../common/decorators/current-user.decorator");
const user_entity_1 = require("../../users/domain/user.entity");
const client_1 = require("@prisma/client");
let PlantsController = class PlantsController {
    plantsService;
    constructor(plantsService) {
        this.plantsService = plantsService;
    }
    async findAll(user) {
        if (user.role === client_1.Role.ADMIN) {
            return this.plantsService.findAll();
        }
        return this.plantsService.findAllByOwner(user.id);
    }
    async findOne(id, user) {
        const plant = await this.plantsService.findById(id);
        if (user.role !== client_1.Role.ADMIN && plant.ownerId !== user.id) {
            throw new common_1.ForbiddenException('You do not own this power plant');
        }
        return plant;
    }
    async create(createPlantDto, user) {
        return this.plantsService.create({
            ...createPlantDto,
            ownerId: user.id,
            status: 'Active',
        });
    }
    async update(id, dto, user) {
        const plant = await this.plantsService.findById(id);
        if (user.role !== client_1.Role.ADMIN && plant.ownerId !== user.id) {
            throw new common_1.ForbiddenException('You do not own this power plant');
        }
        return this.plantsService.update(id, dto);
    }
    async remove(id, user) {
        const plant = await this.plantsService.findById(id);
        if (user.role !== client_1.Role.ADMIN && plant.ownerId !== user.id) {
            throw new common_1.ForbiddenException('You do not own this power plant');
        }
        return this.plantsService.delete(id);
    }
    async findPanels(id, user) {
        const plant = await this.plantsService.findById(id);
        if (user.role !== client_1.Role.ADMIN && plant.ownerId !== user.id) {
            throw new common_1.ForbiddenException('You do not own this power plant');
        }
        return this.plantsService.findPanelsByPlant(id);
    }
    async createPanel(id, dto, user) {
        const plant = await this.plantsService.findById(id);
        if (user.role !== client_1.Role.ADMIN && plant.ownerId !== user.id) {
            throw new common_1.ForbiddenException('You do not own this power plant');
        }
        return this.plantsService.createPanel(id, dto);
    }
    async updatePanel(panelId, dto, user) {
        return this.plantsService.updatePanel(panelId, dto);
    }
    async removePanel(panelId, user) {
        return this.plantsService.deletePanel(panelId);
    }
};
exports.PlantsController = PlantsController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], PlantsController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], PlantsController.prototype, "findOne", null);
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_plant_dto_1.CreatePlantDto, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], PlantsController.prototype, "create", null);
__decorate([
    (0, common_1.Put)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], PlantsController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], PlantsController.prototype, "remove", null);
__decorate([
    (0, common_1.Get)(':id/panels'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], PlantsController.prototype, "findPanels", null);
__decorate([
    (0, common_1.Post)(':id/panels'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, create_panel_dto_1.CreatePanelDto,
        user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], PlantsController.prototype, "createPanel", null);
__decorate([
    (0, common_1.Put)('panels/:panelId'),
    __param(0, (0, common_1.Param)('panelId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], PlantsController.prototype, "updatePanel", null);
__decorate([
    (0, common_1.Delete)('panels/:panelId'),
    __param(0, (0, common_1.Param)('panelId')),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], PlantsController.prototype, "removePanel", null);
exports.PlantsController = PlantsController = __decorate([
    (0, common_1.Controller)('plants'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    __metadata("design:paramtypes", [plants_service_1.PlantsService])
], PlantsController);
//# sourceMappingURL=plants.controller.js.map