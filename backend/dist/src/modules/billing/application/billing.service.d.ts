import { IInvoiceRepository } from '../domain/invoice.repository.interface';
import { InvoiceEntity } from '../domain/invoice.entity';
export declare class BillingService {
    private readonly invoiceRepository;
    constructor(invoiceRepository: IInvoiceRepository);
    findById(id: string): Promise<InvoiceEntity>;
    findAll(): Promise<InvoiceEntity[]>;
    findAllByUser(userId: string): Promise<InvoiceEntity[]>;
    create(dto: Partial<InvoiceEntity>): Promise<InvoiceEntity>;
    payInvoice(id: string): Promise<InvoiceEntity>;
    delete(id: string): Promise<boolean>;
}
