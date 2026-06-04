import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { INotificationRepository } from '../domain/notification.repository.interface';
import { NotificationEntity } from '../domain/notification.entity';
import { UsersService } from '../../users/application/users.service';
import { MailService } from './mail.service';

@Injectable()
export class NotificationService {
  constructor(
    @Inject('INotificationRepository')
    private readonly notificationRepository: INotificationRepository,
    private readonly usersService: UsersService,
    private readonly mailService: MailService,
  ) {}

  async findById(id: string): Promise<NotificationEntity> {
    const notification = await this.notificationRepository.findById(id);
    if (!notification) {
      throw new NotFoundException(`Notification with ID ${id} not found`);
    }
    return notification;
  }

  async findByUser(userId: string): Promise<NotificationEntity[]> {
    return this.notificationRepository.findAllByUserId(userId);
  }

  async sendNotification(userId: string, title: string, message: string): Promise<NotificationEntity> {
    // 1. Save to DB
    const notif = await this.notificationRepository.create(userId, title, message);

    // 2. Fetch User to get Email
    try {
      const user = await this.usersService.findById(userId);
      if (user && user.email) {
        // Send email notification asynchronously
        this.mailService.sendMail(
          user.email,
          `Enercore Notification: ${title}`,
          message,
          `<div style="font-family: sans-serif; padding: 20px; border: 1px solid #e5e7eb; border-radius: 8px;">
            <h2 style="color: #2a8c6e;">Enercore Asset Management</h2>
            <hr style="border: 0; border-top: 1px solid #e5e7eb; margin: 15px 0;" />
            <p>Hello <strong>${user.name}</strong>,</p>
            <p>${message}</p>
            <br />
            <p style="font-size: 11px; color: #64748b;">© 2026 Enercore. All rights reserved.</p>
          </div>`
        );
      }
    } catch (e) {
      console.warn('Could not send email for notification:', e.message);
    }

    return notif;
  }

  async markAsRead(id: string): Promise<NotificationEntity> {
    await this.findById(id);
    return this.notificationRepository.markAsRead(id);
  }

  async markAllAsRead(userId: string): Promise<number> {
    return this.notificationRepository.markAllAsRead(userId);
  }
}
