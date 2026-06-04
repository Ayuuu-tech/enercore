import { Module } from '@nestjs/common';
import { VendorsService } from './application/vendors.service';
import { VendorsController } from './presentation/vendors.controller';
import { PrismaVendorRepository } from './infrastructure/prisma-vendor.repository';
import { PrismaModule } from '../../common/prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [VendorsController],
  providers: [
    VendorsService,
    {
      provide: 'IVendorRepository',
      useClass: PrismaVendorRepository,
    },
  ],
  exports: [VendorsService, 'IVendorRepository'],
})
export class VendorsModule {}
