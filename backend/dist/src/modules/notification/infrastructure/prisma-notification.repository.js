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
exports.PrismaNotificationRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../../common/prisma/prisma.service");
const notification_entity_1 = require("../domain/notification.entity");
let PrismaNotificationRepository = class PrismaNotificationRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    mapToEntity(n) {
        return new notification_entity_1.NotificationEntity({
            id: n.id,
            userId: n.userId,
            title: n.title,
            message: n.message,
            read: n.read,
            createdAt: n.createdAt,
        });
    }
    async findById(id) {
        const notification = await this.prisma.notification.findUnique({ where: { id } });
        return notification ? this.mapToEntity(notification) : null;
    }
    async findAllByUserId(userId) {
        const notifications = await this.prisma.notification.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });
        return notifications.map(n => this.mapToEntity(n));
    }
    async create(userId, title, message) {
        const created = await this.prisma.notification.create({
            data: {
                userId,
                title,
                message,
                read: false,
            },
        });
        return this.mapToEntity(created);
    }
    async markAsRead(id) {
        const updated = await this.prisma.notification.update({
            where: { id },
            data: { read: true },
        });
        return this.mapToEntity(updated);
    }
    async markAllAsRead(userId) {
        const result = await this.prisma.notification.updateMany({
            where: { userId, read: false },
            data: { read: true },
        });
        return result.count;
    }
};
exports.PrismaNotificationRepository = PrismaNotificationRepository;
exports.PrismaNotificationRepository = PrismaNotificationRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PrismaNotificationRepository);
//# sourceMappingURL=prisma-notification.repository.js.map