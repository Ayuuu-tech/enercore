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
exports.PrismaTicketRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../../common/prisma/prisma.service");
const ticket_entity_1 = require("../domain/ticket.entity");
let PrismaTicketRepository = class PrismaTicketRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    mapTicketToEntity(t) {
        return new ticket_entity_1.TicketEntity({
            id: t.id,
            ticketNumber: t.ticketNumber,
            title: t.title,
            description: t.description,
            status: t.status,
            priority: t.priority,
            lastUpdateMessage: t.lastUpdateMessage,
            userId: t.userId,
            plantId: t.plantId,
            createdAt: t.createdAt,
            updatedAt: t.updatedAt,
            comments: t.comments?.map(c => new ticket_entity_1.TicketCommentEntity({
                id: c.id,
                ticketId: c.ticketId,
                userId: c.userId,
                message: c.message,
                createdAt: c.createdAt,
            })),
        });
    }
    mapCommentToEntity(c) {
        return new ticket_entity_1.TicketCommentEntity({
            id: c.id,
            ticketId: c.ticketId,
            userId: c.userId,
            message: c.message,
            createdAt: c.createdAt,
        });
    }
    async findById(id) {
        const t = await this.prisma.ticket.findUnique({
            where: { id },
            include: { comments: true },
        });
        return t ? this.mapTicketToEntity(t) : null;
    }
    async findAll() {
        const tickets = await this.prisma.ticket.findMany({
            include: { comments: true },
            orderBy: { updatedAt: 'desc' },
        });
        return tickets.map(t => this.mapTicketToEntity(t));
    }
    async findAllByUserId(userId) {
        const tickets = await this.prisma.ticket.findMany({
            where: { userId },
            include: { comments: true },
            orderBy: { updatedAt: 'desc' },
        });
        return tickets.map(t => this.mapTicketToEntity(t));
    }
    async create(userId, ticket) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        const ticketNumber = `TKT-${uniqueSuffix}`;
        const created = await this.prisma.ticket.create({
            data: {
                ticketNumber,
                title: ticket.title,
                description: ticket.description,
                status: ticket.status || 'OPEN',
                priority: ticket.priority || 'MEDIUM',
                userId,
                plantId: ticket.plantId,
                lastUpdateMessage: 'Ticket raised successfully.',
            },
        });
        return this.mapTicketToEntity(created);
    }
    async update(id, ticket) {
        const updated = await this.prisma.ticket.update({
            where: { id },
            data: {
                title: ticket.title,
                description: ticket.description,
                status: ticket.status,
                priority: ticket.priority,
                lastUpdateMessage: ticket.lastUpdateMessage,
            },
        });
        return this.mapTicketToEntity(updated);
    }
    async delete(id) {
        await this.prisma.ticket.delete({ where: { id } });
        return true;
    }
    async findCommentsByTicketId(ticketId) {
        const comments = await this.prisma.ticketComment.findMany({
            where: { ticketId },
            orderBy: { createdAt: 'asc' },
        });
        return comments.map(c => this.mapCommentToEntity(c));
    }
    async createComment(ticketId, userId, message) {
        const comment = await this.prisma.$transaction(async (tx) => {
            const c = await tx.ticketComment.create({
                data: {
                    ticketId,
                    userId,
                    message,
                },
            });
            await tx.ticket.update({
                where: { id: ticketId },
                data: {
                    lastUpdateMessage: message.length > 50 ? `${message.substring(0, 47)}...` : message,
                },
            });
            return c;
        });
        return this.mapCommentToEntity(comment);
    }
};
exports.PrismaTicketRepository = PrismaTicketRepository;
exports.PrismaTicketRepository = PrismaTicketRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PrismaTicketRepository);
//# sourceMappingURL=prisma-ticket.repository.js.map