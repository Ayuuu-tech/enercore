import { PrismaService } from '../../../common/prisma/prisma.service';
import { IOrderRepository } from '../domain/order.repository.interface';
import { OrderEntity } from '../domain/order.entity';
import { OrderStatus } from '@prisma/client';
export declare class PrismaOrderRepository implements IOrderRepository {
    private prisma;
    constructor(prisma: PrismaService);
    private mapToEntity;
    findById(id: string): Promise<OrderEntity | null>;
    findAll(): Promise<OrderEntity[]>;
    findAllByUserId(userId: string): Promise<OrderEntity[]>;
    create(userId: string, items: {
        productId: string;
        quantity: number;
    }[]): Promise<OrderEntity>;
    updateStatus(id: string, status: OrderStatus): Promise<OrderEntity>;
}
