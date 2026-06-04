import { INotificationRepository } from '../domain/notification.repository.interface';
import { NotificationEntity } from '../domain/notification.entity';
import { UsersService } from '../../users/application/users.service';
import { MailService } from './mail.service';
export declare class NotificationService {
    private readonly notificationRepository;
    private readonly usersService;
    private readonly mailService;
    constructor(notificationRepository: INotificationRepository, usersService: UsersService, mailService: MailService);
    findById(id: string): Promise<NotificationEntity>;
    findByUser(userId: string): Promise<NotificationEntity[]>;
    sendNotification(userId: string, title: string, message: string): Promise<NotificationEntity>;
    markAsRead(id: string): Promise<NotificationEntity>;
    markAllAsRead(userId: string): Promise<number>;
}
