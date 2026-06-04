import { Module } from '@nestjs/common';
import { TelemetryService } from './application/telemetry.service';
import { TelemetryController } from './presentation/telemetry.controller';
import { PrismaTelemetryRepository } from './infrastructure/prisma-telemetry.repository';
import { PrismaModule } from '../../common/prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [TelemetryController],
  providers: [
    TelemetryService,
    {
      provide: 'ITelemetryRepository',
      useClass: PrismaTelemetryRepository,
    },
  ],
  exports: [TelemetryService, 'ITelemetryRepository'],
})
export class TelemetryModule {}
