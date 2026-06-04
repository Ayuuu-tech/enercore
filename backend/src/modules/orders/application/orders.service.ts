import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { IOrderRepository } from '../domain/order.repository.interface';
import { OrderEntity } from '../domain/order.entity';
import { OrderStatus } from '@prisma/client';

@Injectable()
export class OrdersService {
  constructor(
    @Inject('IOrderRepository')
    private readonly orderRepository: IOrderRepository,
  ) {}

  async findById(id: string): Promise<OrderEntity> {
    const order = await this.orderRepository.findById(id);
    if (!order) {
      throw new NotFoundException(`Order with ID ${id} not found`);
    }
    return order;
  }

  async findAll(): Promise<OrderEntity[]> {
    return this.orderRepository.findAll();
  }

  async findAllByUser(userId: string): Promise<OrderEntity[]> {
    return this.orderRepository.findAllByUserId(userId);
  }

  async createOrder(userId: string, items: { productId: string; quantity: number }[]): Promise<OrderEntity> {
    return this.orderRepository.create(userId, items);
  }

  async updateStatus(id: string, status: OrderStatus): Promise<OrderEntity> {
    await this.findById(id);
    return this.orderRepository.updateStatus(id, status);
  }
}
