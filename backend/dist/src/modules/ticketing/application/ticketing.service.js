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
exports.TicketingService = void 0;
const common_1 = require("@nestjs/common");
let TicketingService = class TicketingService {
    ticketRepository;
    constructor(ticketRepository) {
        this.ticketRepository = ticketRepository;
    }
    async findById(id) {
        const ticket = await this.ticketRepository.findById(id);
        if (!ticket) {
            throw new common_1.NotFoundException(`Ticket with ID ${id} not found`);
        }
        return ticket;
    }
    async findAll() {
        return this.ticketRepository.findAll();
    }
    async findAllByUser(userId) {
        return this.ticketRepository.findAllByUserId(userId);
    }
    async createTicket(userId, dto) {
        return this.ticketRepository.create(userId, dto);
    }
    async updateTicket(id, dto) {
        await this.findById(id);
        return this.ticketRepository.update(id, dto);
    }
    async deleteTicket(id) {
        await this.findById(id);
        return this.ticketRepository.delete(id);
    }
    async getComments(ticketId) {
        await this.findById(ticketId);
        return this.ticketRepository.findCommentsByTicketId(ticketId);
    }
    async addComment(ticketId, userId, message) {
        await this.findById(ticketId);
        return this.ticketRepository.createComment(ticketId, userId, message);
    }
};
exports.TicketingService = TicketingService;
exports.TicketingService = TicketingService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, common_1.Inject)('ITicketRepository')),
    __metadata("design:paramtypes", [Object])
], TicketingService);
//# sourceMappingURL=ticketing.service.js.map