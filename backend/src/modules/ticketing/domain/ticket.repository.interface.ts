import { TicketEntity, TicketCommentEntity } from './ticket.entity';
import { TicketPriority, TicketStatus } from '@prisma/client';

export interface ITicketRepository {
  findById(id: string): Promise<TicketEntity | null>;
  findAll(page?: number, limit?: number): Promise<TicketEntity[]>;
  findAllByUserId(userId: string, page?: number, limit?: number): Promise<TicketEntity[]>;
  create(userId: string, ticket: Partial<TicketEntity>): Promise<TicketEntity>;
  update(id: string, ticket: Partial<TicketEntity>): Promise<TicketEntity>;
  delete(id: string): Promise<boolean>;

  // Comments
  findCommentsByTicketId(ticketId: string): Promise<TicketCommentEntity[]>;
  createComment(ticketId: string, userId: string, message: string): Promise<TicketCommentEntity>;
}
