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
import { customerUnitPrice } from '../../../common/util/pricing';

@Controller('orders')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  /**
   * Customers are shown the unit price *they* paid — the vendor's price with
   * Enercore's commission already folded in. Handing them the vendor's raw
   * price would let them subtract it from the order total and read off the
   * commission. Vendors and admins see the true vendor price, since that is
   * what the vendor is paid.
   */
  private forCustomer<T extends { items?: { priceAtPurchase: number }[] }>(order: T): T {
    if (!order.items) return order;
    return {
      ...order,
      items: order.items.map((i) => ({
        ...i,
        priceAtPurchase: customerUnitPrice(i.priceAtPurchase),
      })),
    };
  }

  @Get()
  async findAll(@CurrentUser() user: UserEntity) {
    if (user.role === Role.ADMIN) {
      return this.ordersService.findAll();
    }
    if (user.role === Role.VENDOR) {
      return this.ordersService.findAllByVendor(user.id);
    }
    const orders = await this.ordersService.findAllByUser(user.id);
    return orders.map((o) => this.forCustomer(o));
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @CurrentUser() user: UserEntity) {
    const order = await this.ordersService.findById(id);
    if (user.role !== Role.ADMIN && order.userId !== user.id) {
      throw new ForbiddenException('You do not have permission to view this order');
    }
    return user.role === Role.CLIENT ? this.forCustomer(order) : order;
  }

  @Post()
  async create(@Body() dto: CreateOrderDto, @CurrentUser() user: UserEntity) {
    const order = await this.ordersService.createOrder(user.id, dto.items);
    return user.role === Role.CLIENT ? this.forCustomer(order) : order;
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
