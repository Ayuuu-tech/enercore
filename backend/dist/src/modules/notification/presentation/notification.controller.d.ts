import { NotificationService } from '../application/notification.service';
import { UserEntity } from '../../users/domain/user.entity';
export declare class NotificationController {
    private readonly notificationService;
    constructor(notificationService: NotificationService);
    findAll(user: UserEntity): Promise<import("../domain/notification.entity").NotificationEntity[]>;
    send(body: {
        userId: string;
        title: string;
        message: string;
    }): Promise<import("../domain/notification.entity").NotificationEntity>;
    readAll(user: UserEntity): Promise<{
        count: number;
    }>;
    markRead(id: string, user: UserEntity): Promise<import("../domain/notification.entity").NotificationEntity>;
}
