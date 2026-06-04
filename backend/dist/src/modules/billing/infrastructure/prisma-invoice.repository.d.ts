import { PrismaService } from '../../../common/prisma/prisma.service';
import { IInvoiceRepository } from '../domain/invoice.repository.interface';
import { InvoiceEntity } from '../domain/invoice.entity';
export declare class PrismaInvoiceRepository implements IInvoiceRepository {
    private prisma;
    constructor(prisma: PrismaService);
    private mapToEntity;
    findById(id: string): Promise<InvoiceEntity | null>;
    findAll(): Promise<InvoiceEntity[]>;
    findAllByUserId(userId: string): Promise<InvoiceEntity[]>;
    create(invoice: Partial<InvoiceEntity>): Promise<InvoiceEntity>;
    update(id: string, invoice: Partial<InvoiceEntity>): Promise<InvoiceEntity>;
    delete(id: string): Promise<boolean>;
}
