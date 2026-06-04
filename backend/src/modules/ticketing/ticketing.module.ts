import { Module } from '@nestjs/common';
import { TicketingService } from './application/ticketing.service';
import { TicketingController } from './presentation/ticketing.controller';
import { PrismaTicketRepository } from './infrastructure/prisma-ticket.repository';
import { PrismaModule } from '../../common/prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [TicketingController],
  providers: [
    TicketingService,
    {
      provide: 'ITicketRepository',
      useClass: PrismaTicketRepository,
    },
  ],
  exports: [TicketingService, 'ITicketRepository'],
})
export class TicketingModule {}
