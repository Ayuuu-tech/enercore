import { OrdersService } from '../application/orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { UserEntity } from '../../users/domain/user.entity';
import { OrderStatus } from '@prisma/client';
export declare class OrdersController {
    private readonly ordersService;
    constructor(ordersService: OrdersService);
    findAll(user: UserEntity): Promise<import("../domain/order.entity").OrderEntity[]>;
    findOne(id: string, user: UserEntity): Promise<import("../domain/order.entity").OrderEntity>;
    create(dto: CreateOrderDto, user: UserEntity): Promise<import("../domain/order.entity").OrderEntity>;
    updateStatus(id: string, body: {
        status: OrderStatus;
    }): Promise<import("../domain/order.entity").OrderEntity>;
}
