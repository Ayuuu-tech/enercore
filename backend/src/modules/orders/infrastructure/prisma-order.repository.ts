import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { IOrderRepository } from '../domain/order.repository.interface';
import { OrderEntity, OrderItemEntity } from '../domain/order.entity';
import { Order as PrismaOrder, OrderItem as PrismaOrderItem, OrderStatus } from '@prisma/client';
import { priceBreakdown } from '../../../common/util/pricing';

@Injectable()
export class PrismaOrderRepository implements IOrderRepository {
  constructor(private prisma: PrismaService) {}

  private mapToEntity(o: PrismaOrder & { items?: PrismaOrderItem[] }): OrderEntity {
    return new OrderEntity({
      id: o.id,
      orderNumber: o.orderNumber,
      gstAmount: o.gstAmount,
      totalAmount: o.totalAmount,
      status: o.status,
      userId: o.userId,
      createdAt: o.createdAt,
      updatedAt: o.updatedAt,
      items: o.items?.map(
        i =>
          new OrderItemEntity({
            id: i.id,
            orderId: i.orderId,
            productId: i.productId,
            quantity: i.quantity,
            priceAtPurchase: i.priceAtPurchase,
          }),
      ),
    });
  }

  async findById(id: string): Promise<OrderEntity | null> {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: { items: true },
    });
    return order ? this.mapToEntity(order) : null;
  }

  async findAll(): Promise<OrderEntity[]> {
    const orders = await this.prisma.order.findMany({
      include: { items: true },
      orderBy: { createdAt: 'desc' },
    });
    return orders.map(o => this.mapToEntity(o));
  }

  async findAllByUserId(userId: string): Promise<OrderEntity[]> {
    const orders = await this.prisma.order.findMany({
      where: { userId },
      include: { items: true },
      orderBy: { createdAt: 'desc' },
    });
    return orders.map(o => this.mapToEntity(o));
  }

  async findAllByVendorId(vendorId: string): Promise<OrderEntity[]> {
    const orders = await this.prisma.order.findMany({
      where: { items: { some: { product: { vendorId } } } },
      include: { items: true },
      orderBy: { createdAt: 'desc' },
    });
    return orders.map(o => this.mapToEntity(o));
  }

  async create(userId: string, items: { productId: string; quantity: number }[]): Promise<OrderEntity> {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const orderNumber = `ORD-${uniqueSuffix}`;

    const order = await this.prisma.$transaction(async (tx) => {
      // Sum of what the vendors listed. Enercore's commission and GST are
      // applied on top, once, below.
      let subtotal = 0;
      const orderItemsToCreate: { productId: string; quantity: number; priceAtPurchase: number }[] = [];

      for (const item of items) {
        const product = await tx.product.findUnique({
          where: { id: item.productId },
        });

        if (!product) {
          throw new NotFoundException(`Product with ID ${item.productId} not found`);
        }

        if (product.stock < item.quantity) {
          throw new BadRequestException(
            `Insufficient stock for product "${product.title}". Available: ${product.stock}, Requested: ${item.quantity}`,
          );
        }

        // Deduct stock
        await tx.product.update({
          where: { id: item.productId },
          data: { stock: product.stock - item.quantity },
        });

        const priceAtPurchase = product.price;
        subtotal += priceAtPurchase * item.quantity;

        orderItemsToCreate.push({
          productId: item.productId,
          quantity: item.quantity,
          priceAtPurchase,
        });
      }

      // The customer is charged exactly what the app quoted them.
      const price = priceBreakdown(subtotal);

      // Create Order
      const newOrder = await tx.order.create({
        data: {
          orderNumber,
          subtotal: price.subtotal,
          platformFee: price.platformFee,
          gstAmount: price.gst,
          totalAmount: price.total,
          userId,
          status: OrderStatus.PENDING,
          items: {
            create: orderItemsToCreate,
          },
        },
        include: { items: true },
      });

      return newOrder;
    });

    return this.mapToEntity(order);
  }

  async updateStatus(id: string, status: OrderStatus): Promise<OrderEntity> {
    const updated = await this.prisma.order.update({
      where: { id },
      data: { status },
      include: { items: true },
    });
    return this.mapToEntity(updated);
  }
}
