import {
  BadRequestException,
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  Post,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { Response } from 'express';
import { BillingService } from '../application/billing.service';
import { BillGenerationService } from '../application/bill-generation.service';
import { BillPdfService } from '../application/bill-pdf.service';
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
  constructor(
    private readonly billingService: BillingService,
    private readonly billGeneration: BillGenerationService,
    private readonly billPdf: BillPdfService,
  ) {}

  /** Download the solar bill of supply for an invoice, as a PDF. */
  @Get(':id/pdf')
  async downloadPdf(
    @Param('id') id: string,
    @CurrentUser() user: UserEntity,
    @Res() res: Response,
  ) {
    const invoice = await this.billingService.findById(id);
    if (user.role !== Role.ADMIN && invoice.userId !== user.id) {
      throw new ForbiddenException('You do not have permission to view this invoice');
    }
    const { buffer, filename } = await this.billPdf.generate(id);
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Content-Length': buffer.length,
    });
    res.send(buffer);
  }

  /**
   * Manually (re-)run bill generation for a month, e.g. "2026-06".
   * Safe to call repeatedly — already-billed plants are skipped.
   */
  @Post('generate')
  @Roles(Role.ADMIN)
  async generate(@Body() body: { period?: string }) {
    const period = body?.period;
    if (!period || !/^\d{4}-\d{2}$/.test(period)) {
      throw new BadRequestException('period must be "YYYY-MM"');
    }
    return this.billGeneration.generateForMonth(period);
  }

  @Get()
  async findAll(
    @CurrentUser() user: UserEntity,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = Math.max(1, parseInt(page ?? '1', 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit ?? '100', 10) || 100));

    if (user.role === Role.ADMIN) {
      return this.billingService.findAll(pageNum, limitNum);
    }
    return this.billingService.findAllByUser(user.id, pageNum, limitNum);
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
