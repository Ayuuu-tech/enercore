import { Module } from '@nestjs/common';
import { BillingService } from './application/billing.service';
import { BillingController } from './presentation/billing.controller';
import { PrismaInvoiceRepository } from './infrastructure/prisma-invoice.repository';
import { PrismaModule } from '../../common/prisma/prisma.module';
import { BillGenerationService } from './application/bill-generation.service';
import { BillPdfService } from './application/bill-pdf.service';

@Module({
  imports: [PrismaModule],
  controllers: [BillingController],
  providers: [
    BillingService,
    BillGenerationService,
    BillPdfService,
    {
      provide: 'IInvoiceRepository',
      useClass: PrismaInvoiceRepository,
    },
  ],
  exports: [BillingService, 'IInvoiceRepository'],
})
export class BillingModule {}
