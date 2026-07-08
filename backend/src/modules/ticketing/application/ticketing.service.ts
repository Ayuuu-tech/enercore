import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { ITicketRepository } from '../domain/ticket.repository.interface';
import { TicketEntity, TicketCommentEntity } from '../domain/ticket.entity';
import { TicketPriority, TicketStatus } from '@prisma/client';

@Injectable()
export class TicketingService {
  constructor(
    @Inject('ITicketRepository')
    private readonly ticketRepository: ITicketRepository,
  ) {}

  async findById(id: string): Promise<TicketEntity> {
    const ticket = await this.ticketRepository.findById(id);
    if (!ticket) {
      throw new NotFoundException(`Ticket with ID ${id} not found`);
    }
    return ticket;
  }

  async findAll(page = 1, limit = 100): Promise<TicketEntity[]> {
    return this.ticketRepository.findAll(page, limit);
  }

  async findAllByUser(userId: string, page = 1, limit = 100): Promise<TicketEntity[]> {
    return this.ticketRepository.findAllByUserId(userId, page, limit);
  }

  async createTicket(userId: string, dto: Partial<TicketEntity>): Promise<TicketEntity> {
    return this.ticketRepository.create(userId, dto);
  }

  async updateTicket(id: string, dto: Partial<TicketEntity>): Promise<TicketEntity> {
    await this.findById(id);
    return this.ticketRepository.update(id, dto);
  }

  async deleteTicket(id: string): Promise<boolean> {
    await this.findById(id);
    return this.ticketRepository.delete(id);
  }

  // Comments
  async getComments(ticketId: string): Promise<TicketCommentEntity[]> {
    await this.findById(ticketId);
    return this.ticketRepository.findCommentsByTicketId(ticketId);
  }

  async addComment(ticketId: string, userId: string, message: string): Promise<TicketCommentEntity> {
    await this.findById(ticketId);
    return this.ticketRepository.createComment(ticketId, userId, message);
  }
}
