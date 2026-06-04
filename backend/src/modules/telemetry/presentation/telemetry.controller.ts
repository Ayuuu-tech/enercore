import { Controller, Get, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { TelemetryService } from '../application/telemetry.service';
import { CreateTelemetryDto } from './dto/create-telemetry.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';

@Controller('telemetry')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TelemetryController {
  constructor(private readonly telemetryService: TelemetryService) {}

  @Post()
  async logTelemetry(@Body() dto: CreateTelemetryDto) {
    return this.telemetryService.logTelemetry(dto);
  }

  @Get('plant/:plantId')
  async findByPlant(
    @Param('plantId') plantId: string,
    @Query('limit') limit?: string,
  ) {
    const limitNum = limit ? parseInt(limit, 10) : 100;
    return this.telemetryService.findByPlant(plantId, limitNum);
  }

  @Get('plant/:plantId/latest')
  async findLatestByPlant(@Param('plantId') plantId: string) {
    return this.telemetryService.findLatestByPlant(plantId);
  }
}
