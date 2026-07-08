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

@Controller('telemetry')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TelemetryController {
  constructor(
    private readonly telemetryService: TelemetryService,
    private readonly tracksoReportService: TracksoReportService,
    private readonly plantAccess: PlantAccessService,
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
    const { buffer, filename } = await this.tracksoReportService.generateSiteReport(
      plantId,
      frequency,
      date ?? Date.now(),
    );
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
    return this.tracksoReportService.getPeriodYields(allowed);
  }

  @Get('plant/:plantId/devices')
  async getDevices(@Param('plantId') plantId: string, @CurrentUser() user: UserEntity) {
    await this.plantAccess.assertPlantAccess(user, plantId);
    return this.tracksoReportService.getDevices(plantId);
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
