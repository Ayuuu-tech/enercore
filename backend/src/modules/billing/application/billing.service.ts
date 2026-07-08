import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { IInvoiceRepository } from '../domain/invoice.repository.interface';
import { InvoiceEntity } from '../domain/invoice.entity';
import { InvoiceStatus } from '@prisma/client';

@Injectable()
export class BillingService {
  constructor(
    @Inject('IInvoiceRepository')
    private readonly invoiceRepository: IInvoiceRepository,
  ) {}

  async findById(id: string): Promise<InvoiceEntity> {
    const invoice = await this.invoiceRepository.findById(id);
    if (!invoice) {
      throw new NotFoundException(`Invoice with ID ${id} not found`);
    }
    return invoice;
  }

  async findAll(page = 1, limit = 100): Promise<InvoiceEntity[]> {
    return this.invoiceRepository.findAll(page, limit);
  }

  async findAllByUser(userId: string, page = 1, limit = 100): Promise<InvoiceEntity[]> {
    return this.invoiceRepository.findAllByUserId(userId, page, limit);
  }

  async create(dto: Partial<InvoiceEntity>): Promise<InvoiceEntity> {
    // Generate a default invoice number if not provided
    if (!dto.invoiceNumber) {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
      dto.invoiceNumber = `INV-${uniqueSuffix}`;
    }
    return this.invoiceRepository.create(dto);
  }

  async payInvoice(id: string): Promise<InvoiceEntity> {
    const invoice = await this.findById(id);
    return this.invoiceRepository.update(id, {
      status: InvoiceStatus.PAID,
      paidAt: new Date(),
    });
  }

  async delete(id: string): Promise<boolean> {
    await this.findById(id);
    return this.invoiceRepository.delete(id);
  }
}
