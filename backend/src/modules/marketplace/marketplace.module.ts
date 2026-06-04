import { Module } from '@nestjs/common';
import { MarketplaceService } from './application/marketplace.service';
import { MarketplaceController } from './presentation/marketplace.controller';
import { PrismaProductRepository } from './infrastructure/prisma-product.repository';
import { PrismaModule } from '../../common/prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [MarketplaceController],
  providers: [
    MarketplaceService,
    {
      provide: 'IProductRepository',
      useClass: PrismaProductRepository,
    },
  ],
  exports: [MarketplaceService, 'IProductRepository'],
})
export class MarketplaceModule {}
