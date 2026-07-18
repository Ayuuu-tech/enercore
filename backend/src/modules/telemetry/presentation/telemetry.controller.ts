import { Controller, Get, Post, Body, Param, Query, UseGuards, Res, BadRequestException } from '@nestjs/common';
import { Response } from 'express';
import { TelemetryService } from '../application/telemetry.service';
import { TracksoReportService, ReportFrequency } from '../application/trackso-report.service';
import { CreateTelemetryDto } from './dto/create-telemetry.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { UserEntity } from '../../users/domain/user.entity';
import { PlantAccessService } from '../../../common/access/plant-access.service';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { IoNextSyncService } from '../application/ionext-sync.service';
import { IoNextService } from '../application/ionext.service';
import { istDay } from '../../../common/util/ist-day';

@Controller('telemetry')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TelemetryController {
  constructor(
    private readonly telemetryService: TelemetryService,
    private readonly tracksoReportService: TracksoReportService,
    private readonly plantAccess: PlantAccessService,
    private readonly prisma: PrismaService,
    private readonly ioNextSync: IoNextSyncService,
    private readonly ioNext: IoNextService,
  ) {}

  @Post('reports/site')
  async generateSiteReport(
    @Body() body: { plantId: string; frequency: ReportFrequency; date?: number },
    @CurrentUser() user: UserEntity,
    @Res() res: Response,
  ) {
    const { plantId, frequency, date } = body;
    if (!plantId || !frequency) {
      throw new BadRequestException('plantId and frequency are required');
    }
    await this.plantAccess.assertPlantAccess(user, plantId);
    const plant = await this.prisma.plant.findUnique({ where: { id: plantId } });
    const { buffer, filename } =
      plant?.dataSource === 'IONEXT' && plant.externalKey
        ? await this.ioNext.generateReport(plant.externalKey, plant.id, plant.name, plant.peakCapacity, frequency)
        : await this.tracksoReportService.generateSiteReport(plantId, frequency, date ?? Date.now());
    res.set({
      'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Content-Length': buffer.length,
    });
    res.send(buffer);
  }

  @Get('dashboard')
  async getDashboard(@CurrentUser() user: UserEntity) {
    const allowed = await this.plantAccess.getAccessibleSiteKeys(user);
    return this.telemetryService.getDashboardStats(allowed);
  }

  @Get('alarms')
  async getAlarms(@CurrentUser() user: UserEntity) {
    const allowed = await this.plantAccess.getAccessibleSiteKeys(user);
    return this.tracksoReportService.getOpenAlarms(allowed);
  }

  @Get('period-yield')
  async getPeriodYield(@CurrentUser() user: UserEntity) {
    const allowed = await this.plantAccess.getAccessibleSiteKeys(user);
    // Split the allow-list: Trackso site keys vs namespaced IO.Next keys.
    const tracksoKeys = allowed === null ? null : allowed.filter((k) => !k.startsWith('IN:'));
    const ioNextKeys = allowed === null ? null : allowed.filter((k) => k.startsWith('IN:'));
    const [trackso, ioNext] = await Promise.all([
      this.tracksoReportService.getPeriodYields(tracksoKeys),
      this.ioNextSync.getPeriodContribution(ioNextKeys),
    ]);
    return {
      day: parseFloat((trackso.day + ioNext.day).toFixed(1)),
      week: parseFloat((trackso.week + ioNext.week).toFixed(1)),
      month: parseFloat((trackso.month + ioNext.month).toFixed(1)),
      year: parseFloat((trackso.year + ioNext.year).toFixed(1)),
    };
  }

  @Get('plant/:plantId/devices')
  async getDevices(@Param('plantId') plantId: string, @CurrentUser() user: UserEntity) {
    await this.plantAccess.assertPlantAccess(user, plantId);
    const plant = await this.prisma.plant.findUnique({ where: { id: plantId } });
    if (plant?.dataSource === 'IONEXT' && plant.externalKey) {
      return this.ioNextSync.getDevices(plantId, plant.externalKey);
    }
    return this.tracksoReportService.getDevices(plantId);
  }

  /**
   * Per-device daily generation over the last N days — the "generation by
   * inverter" bar chart. Read from the daily snapshots we record for every
   * plant, so it's the same source (and the same numbers) as billing.
   */
  @Get('plant/:plantId/device-daily')
  async getDeviceDaily(
    @Param('plantId') plantId: string,
    @CurrentUser() user: UserEntity,
    @Query('days') days?: string,
  ) {
    await this.plantAccess.assertPlantAccess(user, plantId);
    const n = Math.min(90, Math.max(1, parseInt(days ?? '14', 10) || 14));
    const from = istDay(Date.now() - (n - 1) * 24 * 60 * 60 * 1000);

    const rows = await this.prisma.deviceDailyEnergy.findMany({
      where: { plantId, day: { gte: from } },
      orderBy: { day: 'asc' },
      select: { deviceName: true, day: true, energyKwh: true },
    });

    // Stable device order, and a value per device per day (0 when a device
    // didn't report that day) so the chart's grouped bars stay aligned.
    const devices = [...new Set(rows.map((r) => r.deviceName))].sort();
    const byDay = new Map<string, Record<string, number>>();
    for (const r of rows) {
      (byDay.get(r.day) ?? byDay.set(r.day, {}).get(r.day)!)[r.deviceName] = r.energyKwh;
    }
    const series = [...byDay.entries()].map(([day, vals]) => ({
      day,
      values: devices.map((d) => parseFloat((vals[d] ?? 0).toFixed(1))),
    }));
    return { devices, series };
  }

  @Post()
  async logTelemetry(@Body() dto: CreateTelemetryDto) {
    return this.telemetryService.logTelemetry(dto);
  }

  @Get('plant/:plantId')
  async findByPlant(
    @Param('plantId') plantId: string,
    @CurrentUser() user: UserEntity,
    @Query('limit') limit?: string,
  ) {
    await this.plantAccess.assertPlantAccess(user, plantId);
    const limitNum = limit ? parseInt(limit, 10) : 100;
    return this.telemetryService.findByPlant(plantId, limitNum);
  }

  @Get('plant/:plantId/latest')
  async findLatestByPlant(@Param('plantId') plantId: string, @CurrentUser() user: UserEntity) {
    await this.plantAccess.assertPlantAccess(user, plantId);
    return this.telemetryService.findLatestByPlant(plantId);
  }

  @Get('plant/:plantId/series')
  async getSeriesByPlant(
    @Param('plantId') plantId: string,
    @CurrentUser() user: UserEntity,
    @Query('hours') hours?: string,
  ) {
    await this.plantAccess.assertPlantAccess(user, plantId);
    const hoursNum = Math.min(Math.max(parseInt(hours ?? '6', 10) || 6, 1), 24 * 31);
    return this.telemetryService.getSeriesByPlant(plantId, hoursNum);
  }
}
