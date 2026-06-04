import { Module } from '@nestjs/common';
import { NotificationService } from './application/notification.service';
import { NotificationController } from './presentation/notification.controller';
import { PrismaNotificationRepository } from './infrastructure/prisma-notification.repository';
import { PrismaModule } from '../../common/prisma/prisma.module';
import { UsersModule } from '../users/users.module';
import { MailService } from './application/mail.service';

@Module({
  imports: [PrismaModule, UsersModule],
  controllers: [NotificationController],
  providers: [
    NotificationService,
    MailService,
    {
      provide: 'INotificationRepository',
      useClass: PrismaNotificationRepository,
    },
  ],
  exports: [NotificationService, MailService, 'INotificationRepository'],
})
export class NotificationModule {}
