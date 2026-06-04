import { NotificationEntity } from './notification.entity';

export interface INotificationRepository {
  findById(id: string): Promise<NotificationEntity | null>;
  findAllByUserId(userId: string): Promise<NotificationEntity[]>;
  create(userId: string, title: string, message: string): Promise<NotificationEntity>;
  markAsRead(id: string): Promise<NotificationEntity>;
  markAllAsRead(userId: string): Promise<number>;
}
