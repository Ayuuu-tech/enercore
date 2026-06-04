import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { NotificationService } from '../application/notification.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { UserEntity } from '../../users/domain/user.entity';
import { Role } from '@prisma/client';

@Controller('notifications')
@UseGuards(JwtAuthGuard, RolesGuard)
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Get()
  async findAll(@CurrentUser() user: UserEntity) {
    return this.notificationService.findByUser(user.id);
  }

  @Post()
  @Roles(Role.ADMIN)
  async send(
    @Body() body: { userId: string; title: string; message: string },
  ) {
    return this.notificationService.sendNotification(
      body.userId,
      body.title,
      body.message,
    );
  }

  @Put('read-all')
  async readAll(@CurrentUser() user: UserEntity) {
    const count = await this.notificationService.markAllAsRead(user.id);
    return { count };
  }

  @Put(':id/read')
  async markRead(@Param('id') id: string, @CurrentUser() user: UserEntity) {
    const notif = await this.notificationService.findById(id);
    if (notif.userId !== user.id) {
      throw new ForbiddenException('You do not own this notification');
    }
    return this.notificationService.markAsRead(id);
  }
}
