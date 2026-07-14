import { Module } from '@nestjs/common';
import { VendorsService } from './application/vendors.service';
import { VendorKycController } from './presentation/vendor-kyc.controller';
import { VendorKycService } from './application/vendor-kyc.service';
import { VendorsController } from './presentation/vendors.controller';
import { PrismaVendorRepository } from './infrastructure/prisma-vendor.repository';
import { PrismaModule } from '../../common/prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  // Registered first: VendorsController has @Get(':id'), which would
  // otherwise match /vendors/kyc and treat "kyc" as a vendor id.
  controllers: [VendorKycController, VendorsController],
  providers: [
    VendorKycService,
    VendorsService,
    {
      provide: 'IVendorRepository',
      useClass: PrismaVendorRepository,
    },
  ],
  exports: [VendorsService, 'IVendorRepository'],
})
export class VendorsModule {}
