import { OrderEntity } from './order.entity';
import { OrderStatus } from '@prisma/client';
export interface IOrderRepository {
    findById(id: string): Promise<OrderEntity | null>;
    findAll(): Promise<OrderEntity[]>;
    findAllByUserId(userId: string): Promise<OrderEntity[]>;
    create(userId: string, items: {
        productId: string;
        quantity: number;
    }[]): Promise<OrderEntity>;
    updateStatus(id: string, status: OrderStatus): Promise<OrderEntity>;
}
