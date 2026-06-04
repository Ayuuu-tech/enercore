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
import { OrdersService } from '../application/orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { UserEntity } from '../../users/domain/user.entity';
import { OrderStatus, Role } from '@prisma/client';

@Controller('orders')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Get()
  async findAll(@CurrentUser() user: UserEntity) {
    if (user.role === Role.ADMIN) {
      return this.ordersService.findAll();
    }
    return this.ordersService.findAllByUser(user.id);
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @CurrentUser() user: UserEntity) {
    const order = await this.ordersService.findById(id);
    if (user.role !== Role.ADMIN && order.userId !== user.id) {
      throw new ForbiddenException('You do not have permission to view this order');
    }
    return order;
  }

  @Post()
  async create(@Body() dto: CreateOrderDto, @CurrentUser() user: UserEntity) {
    return this.ordersService.createOrder(user.id, dto.items);
  }

  @Put(':id/status')
  @Roles(Role.ADMIN, Role.VENDOR)
  async updateStatus(
    @Param('id') id: string,
    @Body() body: { status: OrderStatus },
  ) {
    return this.ordersService.updateStatus(id, body.status);
  }
}
