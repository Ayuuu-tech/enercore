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
exports.NotificationService = void 0;
const common_1 = require("@nestjs/common");
const users_service_1 = require("../../users/application/users.service");
const mail_service_1 = require("./mail.service");
let NotificationService = class NotificationService {
    notificationRepository;
    usersService;
    mailService;
    constructor(notificationRepository, usersService, mailService) {
        this.notificationRepository = notificationRepository;
        this.usersService = usersService;
        this.mailService = mailService;
    }
    async findById(id) {
        const notification = await this.notificationRepository.findById(id);
        if (!notification) {
            throw new common_1.NotFoundException(`Notification with ID ${id} not found`);
        }
        return notification;
    }
    async findByUser(userId) {
        return this.notificationRepository.findAllByUserId(userId);
    }
    async sendNotification(userId, title, message) {
        const notif = await this.notificationRepository.create(userId, title, message);
        try {
            const user = await this.usersService.findById(userId);
            if (user && user.email) {
                this.mailService.sendMail(user.email, `Enercore Notification: ${title}`, message, `<div style="font-family: sans-serif; padding: 20px; border: 1px solid #e5e7eb; border-radius: 8px;">
            <h2 style="color: #2a8c6e;">Enercore Asset Management</h2>
            <hr style="border: 0; border-top: 1px solid #e5e7eb; margin: 15px 0;" />
            <p>Hello <strong>${user.name}</strong>,</p>
            <p>${message}</p>
            <br />
            <p style="font-size: 11px; color: #64748b;">© 2026 Enercore. All rights reserved.</p>
          </div>`);
            }
        }
        catch (e) {
            console.warn('Could not send email for notification:', e.message);
        }
        return notif;
    }
    async markAsRead(id) {
        await this.findById(id);
        return this.notificationRepository.markAsRead(id);
    }
    async markAllAsRead(userId) {
        return this.notificationRepository.markAllAsRead(userId);
    }
};
exports.NotificationService = NotificationService;
exports.NotificationService = NotificationService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, common_1.Inject)('INotificationRepository')),
    __metadata("design:paramtypes", [Object, users_service_1.UsersService,
        mail_service_1.MailService])
], NotificationService);
//# sourceMappingURL=notification.service.js.map