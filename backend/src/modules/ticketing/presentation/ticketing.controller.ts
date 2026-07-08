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
import { TicketingService } from '../application/ticketing.service';
import { CreateTicketDto } from './dto/create-ticket.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { UserEntity } from '../../users/domain/user.entity';
import { TicketPriority, TicketStatus, Role } from '@prisma/client';

@Controller('tickets')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TicketingController {
  constructor(private readonly ticketingService: TicketingService) {}

  @Get()
  async findAll(
    @CurrentUser() user: UserEntity,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = Math.max(1, parseInt(page ?? '1', 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit ?? '20', 10) || 20));

    if (user.role === Role.ADMIN) {
      return this.ticketingService.findAll(pageNum, limitNum);
    }
    return this.ticketingService.findAllByUser(user.id, pageNum, limitNum);
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @CurrentUser() user: UserEntity) {
    const ticket = await this.ticketingService.findById(id);
    if (user.role !== Role.ADMIN && ticket.userId !== user.id) {
      throw new ForbiddenException('You do not have permission to view this ticket');
    }
    return ticket;
  }

  @Post()
  async create(@Body() dto: CreateTicketDto, @CurrentUser() user: UserEntity) {
    return this.ticketingService.createTicket(user.id, dto);
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: { status?: TicketStatus; priority?: TicketPriority; lastUpdateMessage?: string },
    @CurrentUser() user: UserEntity,
  ) {
    const ticket = await this.ticketingService.findById(id);
    if (user.role !== Role.ADMIN && ticket.userId !== user.id) {
      throw new ForbiddenException('You do not have permission to update this ticket');
    }
    return this.ticketingService.updateTicket(id, dto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string, @CurrentUser() user: UserEntity) {
    const ticket = await this.ticketingService.findById(id);
    if (user.role !== Role.ADMIN && ticket.userId !== user.id) {
      throw new ForbiddenException('You do not have permission to delete this ticket');
    }
    return this.ticketingService.deleteTicket(id);
  }

  // Comments
  @Get(':id/comments')
  async getComments(@Param('id') id: string, @CurrentUser() user: UserEntity) {
    const ticket = await this.ticketingService.findById(id);
    if (user.role !== Role.ADMIN && ticket.userId !== user.id) {
      throw new ForbiddenException('You do not have permission to view this ticket\'s comments');
    }
    return this.ticketingService.getComments(id);
  }

  @Post(':id/comments')
  async addComment(
    @Param('id') id: string,
    @Body() body: { message: string },
    @CurrentUser() user: UserEntity,
  ) {
    const ticket = await this.ticketingService.findById(id);
    // Client who raised the ticket, or Admin can comment.
    if (user.role !== Role.ADMIN && ticket.userId !== user.id) {
      throw new ForbiddenException('You do not have permission to comment on this ticket');
    }
    return this.ticketingService.addComment(id, user.id, body.message);
  }
}
