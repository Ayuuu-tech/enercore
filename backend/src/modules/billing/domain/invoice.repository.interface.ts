import { InvoiceEntity } from './invoice.entity';

export interface IInvoiceRepository {
  findById(id: string): Promise<InvoiceEntity | null>;
  findAll(): Promise<InvoiceEntity[]>;
  findAllByUserId(userId: string): Promise<InvoiceEntity[]>;
  create(invoice: Partial<InvoiceEntity>): Promise<InvoiceEntity>;
  update(id: string, invoice: Partial<InvoiceEntity>): Promise<InvoiceEntity>;
  delete(id: string): Promise<boolean>;
}
