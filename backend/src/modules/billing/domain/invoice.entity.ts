import { InvoiceStatus } from '@prisma/client';

export class InvoiceEntity {
  id: string;
  invoiceNumber: string;
  amount: number;
  period: string;
  status: InvoiceStatus;
  dueDate: Date;
  paidAt?: Date | null;
  userId: string;
  plantId?: string | null;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial: Partial<InvoiceEntity>) {
    Object.assign(this, partial);
  }
}
