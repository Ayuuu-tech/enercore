import { PrismaService } from '../../../common/prisma/prisma.service';
import { INotificationRepository } from '../domain/notification.repository.interface';
import { NotificationEntity } from '../domain/notification.entity';
export declare class PrismaNotificationRepository implements INotificationRepository {
    private prisma;
    constructor(prisma: PrismaService);
    private mapToEntity;
    findById(id: string): Promise<NotificationEntity | null>;
    findAllByUserId(userId: string): Promise<NotificationEntity[]>;
    create(userId: string, title: string, message: string): Promise<NotificationEntity>;
    markAsRead(id: string): Promise<NotificationEntity>;
    markAllAsRead(userId: string): Promise<number>;
}
