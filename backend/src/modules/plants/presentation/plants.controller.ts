import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { PlantsService } from '../application/plants.service';
import { CreatePlantDto } from './dto/create-plant.dto';
import { CreatePanelDto } from './dto/create-panel.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { UserEntity } from '../../users/domain/user.entity';
import { Role } from '@prisma/client';

@Controller('plants')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PlantsController {
  constructor(private readonly plantsService: PlantsService) {}

  @Get()
  async findAll(@CurrentUser() user: UserEntity) {
    if (user.role === Role.ADMIN) {
      return this.plantsService.findAll();
    }
    return this.plantsService.findAllByOwner(user.id);
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @CurrentUser() user: UserEntity) {
    const plant = await this.plantsService.findById(id);
    if (user.role !== Role.ADMIN && plant.ownerId !== user.id) {
      throw new ForbiddenException('You do not own this power plant');
    }
    return plant;
  }

  @Post()
  async create(@Body() createPlantDto: CreatePlantDto, @CurrentUser() user: UserEntity) {
    return this.plantsService.create({
      ...createPlantDto,
      ownerId: user.id,
      status: 'Active',
    });
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: Partial<CreatePlantDto>,
    @CurrentUser() user: UserEntity,
  ) {
    const plant = await this.plantsService.findById(id);
    if (user.role !== Role.ADMIN && plant.ownerId !== user.id) {
      throw new ForbiddenException('You do not own this power plant');
    }
    return this.plantsService.update(id, dto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string, @CurrentUser() user: UserEntity) {
    const plant = await this.plantsService.findById(id);
    if (user.role !== Role.ADMIN && plant.ownerId !== user.id) {
      throw new ForbiddenException('You do not own this power plant');
    }
    return this.plantsService.delete(id);
  }

  // Panel endpoints
  @Get(':id/panels')
  async findPanels(@Param('id') id: string, @CurrentUser() user: UserEntity) {
    const plant = await this.plantsService.findById(id);
    if (user.role !== Role.ADMIN && plant.ownerId !== user.id) {
      throw new ForbiddenException('You do not own this power plant');
    }
    return this.plantsService.findPanelsByPlant(id);
  }

  @Post(':id/panels')
  async createPanel(
    @Param('id') id: string,
    @Body() dto: CreatePanelDto,
    @CurrentUser() user: UserEntity,
  ) {
    const plant = await this.plantsService.findById(id);
    if (user.role !== Role.ADMIN && plant.ownerId !== user.id) {
      throw new ForbiddenException('You do not own this power plant');
    }
    return this.plantsService.createPanel(id, dto);
  }

  @Put('panels/:panelId')
  async updatePanel(
    @Param('panelId') panelId: string,
    @Body() dto: Partial<CreatePanelDto> & { voltage?: number; current?: number; temperature?: number; generation?: number },
    @CurrentUser() user: UserEntity,
  ) {
    // Ideally we verify plant ownership before updating panel
    return this.plantsService.updatePanel(panelId, dto);
  }

  @Delete('panels/:panelId')
  async removePanel(@Param('panelId') panelId: string, @CurrentUser() user: UserEntity) {
    return this.plantsService.deletePanel(panelId);
  }
}
