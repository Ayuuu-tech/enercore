import { Module } from '@nestjs/common';
import { BillingService } from './application/billing.service';
import { BillingController } from './presentation/billing.controller';
import { PrismaInvoiceRepository } from './infrastructure/prisma-invoice.repository';
import { PrismaModule } from '../../common/prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [BillingController],
  providers: [
    BillingService,
    {
      provide: 'IInvoiceRepository',
      useClass: PrismaInvoiceRepository,
    },
  ],
  exports: [BillingService, 'IInvoiceRepository'],
})
export class BillingModule {}
