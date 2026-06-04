import { Body, Controller, Get, Param, Put, UseGuards } from '@nestjs/common';
import { VendorsService } from '../application/vendors.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { UserEntity } from '../../users/domain/user.entity';
import { Role } from '@prisma/client';

@Controller('vendors')
@UseGuards(JwtAuthGuard, RolesGuard)
export class VendorsController {
  constructor(private readonly vendorsService: VendorsService) {}

  @Get()
  async findAll() {
    return this.vendorsService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.vendorsService.findById(id);
  }

  @Put('me')
  @Roles(Role.VENDOR)
  async updateMe(
    @CurrentUser() user: UserEntity,
    @Body() body: { companyName?: string },
  ) {
    return this.vendorsService.update(user.id, body);
  }

  @Put(':id/verify')
  @Roles(Role.ADMIN)
  async verify(
    @Param('id') id: string,
    @Body() body: { isVerified: boolean },
  ) {
    return this.vendorsService.verifyVendor(id, body.isVerified);
  }
}
