import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { MarketplaceService } from '../application/marketplace.service';
import { CreateProductDto } from './dto/create-product.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { UserEntity } from '../../users/domain/user.entity';
import { Public } from '../../../common/decorators/public.decorator';
import { Role } from '@prisma/client';

@Controller('products')
@UseGuards(JwtAuthGuard, RolesGuard)
export class MarketplaceController {
  constructor(private readonly marketplaceService: MarketplaceService) {}

  @Public()
  @Get()
  async findAll(
    @Query('category') category?: string,
    @Query('search') search?: string,
    @Query('vendorId') vendorId?: string,
  ) {
    return this.marketplaceService.findAll({ category, search, vendorId });
  }

  @Public()
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.marketplaceService.findById(id);
  }

  @Post()
  @Roles(Role.VENDOR)
  async create(@Body() dto: CreateProductDto, @CurrentUser() user: UserEntity) {
    return this.marketplaceService.create({
      ...dto,
      vendorId: user.id,
    });
  }

  @Put(':id')
  @Roles(Role.VENDOR)
  async update(
    @Param('id') id: string,
    @Body() dto: Partial<CreateProductDto>,
    @CurrentUser() user: UserEntity,
  ) {
    const product = await this.marketplaceService.findById(id);
    if (product.vendorId !== user.id) {
      throw new ForbiddenException('You do not own this product listing');
    }
    return this.marketplaceService.update(id, dto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string, @CurrentUser() user: UserEntity) {
    const product = await this.marketplaceService.findById(id);
    if (user.role !== Role.ADMIN && product.vendorId !== user.id) {
      throw new ForbiddenException('You do not have permission to delete this product');
    }
    return this.marketplaceService.delete(id);
  }
}
