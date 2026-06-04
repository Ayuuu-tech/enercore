import { InvoiceStatus } from '@prisma/client';
export declare class InvoiceEntity {
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
    constructor(partial: Partial<InvoiceEntity>);
}
