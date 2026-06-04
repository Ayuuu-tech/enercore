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
exports.TicketingController = void 0;
const common_1 = require("@nestjs/common");
const ticketing_service_1 = require("../application/ticketing.service");
const create_ticket_dto_1 = require("./dto/create-ticket.dto");
const jwt_auth_guard_1 = require("../../../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../../../common/guards/roles.guard");
const current_user_decorator_1 = require("../../../common/decorators/current-user.decorator");
const user_entity_1 = require("../../users/domain/user.entity");
const client_1 = require("@prisma/client");
let TicketingController = class TicketingController {
    ticketingService;
    constructor(ticketingService) {
        this.ticketingService = ticketingService;
    }
    async findAll(user) {
        if (user.role === client_1.Role.ADMIN) {
            return this.ticketingService.findAll();
        }
        return this.ticketingService.findAllByUser(user.id);
    }
    async findOne(id, user) {
        const ticket = await this.ticketingService.findById(id);
        if (user.role !== client_1.Role.ADMIN && ticket.userId !== user.id) {
            throw new common_1.ForbiddenException('You do not have permission to view this ticket');
        }
        return ticket;
    }
    async create(dto, user) {
        return this.ticketingService.createTicket(user.id, dto);
    }
    async update(id, dto, user) {
        const ticket = await this.ticketingService.findById(id);
        if (user.role !== client_1.Role.ADMIN && ticket.userId !== user.id) {
            throw new common_1.ForbiddenException('You do not have permission to update this ticket');
        }
        return this.ticketingService.updateTicket(id, dto);
    }
    async remove(id, user) {
        const ticket = await this.ticketingService.findById(id);
        if (user.role !== client_1.Role.ADMIN && ticket.userId !== user.id) {
            throw new common_1.ForbiddenException('You do not have permission to delete this ticket');
        }
        return this.ticketingService.deleteTicket(id);
    }
    async getComments(id, user) {
        const ticket = await this.ticketingService.findById(id);
        if (user.role !== client_1.Role.ADMIN && ticket.userId !== user.id) {
            throw new common_1.ForbiddenException('You do not have permission to view this ticket\'s comments');
        }
        return this.ticketingService.getComments(id);
    }
    async addComment(id, body, user) {
        const ticket = await this.ticketingService.findById(id);
        if (user.role !== client_1.Role.ADMIN && ticket.userId !== user.id) {
            throw new common_1.ForbiddenException('You do not have permission to comment on this ticket');
        }
        return this.ticketingService.addComment(id, user.id, body.message);
    }
};
exports.TicketingController = TicketingController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], TicketingController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], TicketingController.prototype, "findOne", null);
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_ticket_dto_1.CreateTicketDto, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], TicketingController.prototype, "create", null);
__decorate([
    (0, common_1.Put)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], TicketingController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], TicketingController.prototype, "remove", null);
__decorate([
    (0, common_1.Get)(':id/comments'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], TicketingController.prototype, "getComments", null);
__decorate([
    (0, common_1.Post)(':id/comments'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, user_entity_1.UserEntity]),
    __metadata("design:returntype", Promise)
], TicketingController.prototype, "addComment", null);
exports.TicketingController = TicketingController = __decorate([
    (0, common_1.Controller)('tickets'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    __metadata("design:paramtypes", [ticketing_service_1.TicketingService])
], TicketingController);
//# sourceMappingURL=ticketing.controller.js.map