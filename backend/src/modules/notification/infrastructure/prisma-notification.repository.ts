import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { INotificationRepository } from '../domain/notification.repository.interface';
import { NotificationEntity } from '../domain/notification.entity';
import { Notification as PrismaNotification } from '@prisma/client';

@Injectable()
export class PrismaNotificationRepository implements INotificationRepository {
  constructor(private prisma: PrismaService) {}

  private mapToEntity(n: PrismaNotification): NotificationEntity {
    return new NotificationEntity({
      id: n.id,
      userId: n.userId,
      title: n.title,
      message: n.message,
      read: n.read,
      createdAt: n.createdAt,
    });
  }

  async findById(id: string): Promise<NotificationEntity | null> {
    const notification = await this.prisma.notification.findUnique({ where: { id } });
    return notification ? this.mapToEntity(notification) : null;
  }

  async findAllByUserId(userId: string): Promise<NotificationEntity[]> {
    const notifications = await this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    return notifications.map(n => this.mapToEntity(n));
  }

  async create(userId: string, title: string, message: string): Promise<NotificationEntity> {
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

  async markAsRead(id: string): Promise<NotificationEntity> {
    const updated = await this.prisma.notification.update({
      where: { id },
      data: { read: true },
    });
    return this.mapToEntity(updated);
  }

  async markAllAsRead(userId: string): Promise<number> {
    const result = await this.prisma.notification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });
    return result.count;
  }
}
