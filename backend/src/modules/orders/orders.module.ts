import { Module } from '@nestjs/common';
import { OrdersService } from './application/orders.service';
import { OrdersController } from './presentation/orders.controller';
import { PrismaOrderRepository } from './infrastructure/prisma-order.repository';
import { PrismaModule } from '../../common/prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [OrdersController],
  providers: [
    OrdersService,
    {
      provide: 'IOrderRepository',
      useClass: PrismaOrderRepository,
    },
  ],
  exports: [OrdersService, 'IOrderRepository'],
})
export class OrdersModule {}
