import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { BillingService } from '../application/billing.service';
import { CreateInvoiceDto } from './dto/create-invoice.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { UserEntity } from '../../users/domain/user.entity';
import { Role } from '@prisma/client';

@Controller('billing')
@UseGuards(JwtAuthGuard, RolesGuard)
export class BillingController {
  constructor(private readonly billingService: BillingService) {}

  @Get()
  async findAll(@CurrentUser() user: UserEntity) {
    if (user.role === Role.ADMIN) {
      return this.billingService.findAll();
    }
    return this.billingService.findAllByUser(user.id);
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @CurrentUser() user: UserEntity) {
    const invoice = await this.billingService.findById(id);
    if (user.role !== Role.ADMIN && invoice.userId !== user.id) {
      throw new ForbiddenException('You do not have permission to view this invoice');
    }
    return invoice;
  }

  @Post()
  @Roles(Role.ADMIN)
  async create(@Body() dto: CreateInvoiceDto) {
    return this.billingService.create({
      ...dto,
      dueDate: new Date(dto.dueDate),
    });
  }

  @Post(':id/pay')
  async pay(@Param('id') id: string, @CurrentUser() user: UserEntity) {
    const invoice = await this.billingService.findById(id);
    if (user.role !== Role.ADMIN && invoice.userId !== user.id) {
      throw new ForbiddenException('You do not have permission to pay this invoice');
    }
    return this.billingService.payInvoice(id);
  }
}
