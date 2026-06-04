import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { IInvoiceRepository } from '../domain/invoice.repository.interface';
import { InvoiceEntity } from '../domain/invoice.entity';
import { Invoice as PrismaInvoice } from '@prisma/client';

@Injectable()
export class PrismaInvoiceRepository implements IInvoiceRepository {
  constructor(private prisma: PrismaService) {}

  private mapToEntity(i: PrismaInvoice): InvoiceEntity {
    return new InvoiceEntity({
      id: i.id,
      invoiceNumber: i.invoiceNumber,
      amount: i.amount,
      period: i.period,
      status: i.status,
      dueDate: i.dueDate,
      paidAt: i.paidAt,
      userId: i.userId,
      plantId: i.plantId,
      createdAt: i.createdAt,
      updatedAt: i.updatedAt,
    });
  }

  async findById(id: string): Promise<InvoiceEntity | null> {
    const invoice = await this.prisma.invoice.findUnique({ where: { id } });
    return invoice ? this.mapToEntity(invoice) : null;
  }

  async findAll(): Promise<InvoiceEntity[]> {
    const invoices = await this.prisma.invoice.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return invoices.map(i => this.mapToEntity(i));
  }

  async findAllByUserId(userId: string): Promise<InvoiceEntity[]> {
    const invoices = await this.prisma.invoice.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    return invoices.map(i => this.mapToEntity(i));
  }

  async create(invoice: Partial<InvoiceEntity>): Promise<InvoiceEntity> {
    const created = await this.prisma.invoice.create({
      data: {
        invoiceNumber: invoice.invoiceNumber!,
        amount: invoice.amount!,
        period: invoice.period!,
        status: invoice.status || 'PENDING',
        dueDate: invoice.dueDate!,
        userId: invoice.userId!,
        plantId: invoice.plantId || null,
      },
    });
    return this.mapToEntity(created);
  }

  async update(id: string, invoice: Partial<InvoiceEntity>): Promise<InvoiceEntity> {
    const updated = await this.prisma.invoice.update({
      where: { id },
      data: {
        amount: invoice.amount,
        period: invoice.period,
        status: invoice.status,
        dueDate: invoice.dueDate,
        paidAt: invoice.paidAt,
      },
    });
    return this.mapToEntity(updated);
  }

  async delete(id: string): Promise<boolean> {
    await this.prisma.invoice.delete({ where: { id } });
    return true;
  }
}
