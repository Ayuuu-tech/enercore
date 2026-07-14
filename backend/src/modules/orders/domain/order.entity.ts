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
  /**
   * GST charged on the order. Named because a tax must be.
   * Enercore's commission is deliberately *not* exposed here: it is folded into
   * the price, and neither the customer nor the vendor is shown it. It is
   * persisted on the order row for Enercore's own accounting.
   */
  gstAmount: number;
  /** What the customer pays. */
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
