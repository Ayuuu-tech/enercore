import { IOrderRepository } from '../domain/order.repository.interface';
import { OrderEntity } from '../domain/order.entity';
import { OrderStatus } from '@prisma/client';
export declare class OrdersService {
    private readonly orderRepository;
    constructor(orderRepository: IOrderRepository);
    findById(id: string): Promise<OrderEntity>;
    findAll(): Promise<OrderEntity[]>;
    findAllByUser(userId: string): Promise<OrderEntity[]>;
    createOrder(userId: string, items: {
        productId: string;
        quantity: number;
    }[]): Promise<OrderEntity>;
    updateStatus(id: string, status: OrderStatus): Promise<OrderEntity>;
}
