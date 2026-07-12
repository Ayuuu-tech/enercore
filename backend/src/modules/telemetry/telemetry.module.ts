import { Module } from '@nestjs/common';
import { TelemetryService } from './application/telemetry.service';
import { TelemetryController } from './presentation/telemetry.controller';
import { PrismaTelemetryRepository } from './infrastructure/prisma-telemetry.repository';
import { PrismaModule } from '../../common/prisma/prisma.module';
import { TracksoSyncService } from './application/trackso-sync.service';
import { TracksoReportService } from './application/trackso-report.service';
import { IoNextService } from './application/ionext.service';
import { IoNextSyncService } from './application/ionext-sync.service';

@Module({
  imports: [PrismaModule],
  controllers: [TelemetryController],
  providers: [
    TelemetryService,
    TracksoSyncService,
    TracksoReportService,
    IoNextService,
    IoNextSyncService,
    {
      provide: 'ITelemetryRepository',
      useClass: PrismaTelemetryRepository,
    },
  ],
  exports: [TelemetryService, 'ITelemetryRepository'],
})
export class TelemetryModule {}
