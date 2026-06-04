import { OrderStatus } from '@prisma/client';

export class OrderItemEntity {
  id: string;
  orderId: string;
  productId: string;
  quantity: number;
  priceAtPurchase: number;

  constructor(partial: Partial<OrderItemEntity>) {
    Object.assign(this, partial);
  }
}

export class OrderEntity {
  id: string;
  orderNumber: string;
  totalAmount: number;
  status: OrderStatus;
  userId: string;
  createdAt: Date;
  updatedAt: Date;
  items?: OrderItemEntity[];

  constructor(partial: Partial<OrderEntity>) {
    Object.assign(this, partial);
  }
}
