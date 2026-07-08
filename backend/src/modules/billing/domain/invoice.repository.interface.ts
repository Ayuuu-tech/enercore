import { InvoiceEntity } from './invoice.entity';

export interface IInvoiceRepository {
  findById(id: string): Promise<InvoiceEntity | null>;
  findAll(page?: number, limit?: number): Promise<InvoiceEntity[]>;
  findAllByUserId(userId: string, page?: number, limit?: number): Promise<InvoiceEntity[]>;
  create(invoice: Partial<InvoiceEntity>): Promise<InvoiceEntity>;
  update(id: string, invoice: Partial<InvoiceEntity>): Promise<InvoiceEntity>;
  delete(id: string): Promise<boolean>;
}
