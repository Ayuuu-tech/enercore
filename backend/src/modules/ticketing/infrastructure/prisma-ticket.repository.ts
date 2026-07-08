import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { ITicketRepository } from '../domain/ticket.repository.interface';
import { TicketEntity, TicketCommentEntity } from '../domain/ticket.entity';
import { Ticket as PrismaTicket, TicketComment as PrismaTicketComment } from '@prisma/client';

@Injectable()
export class PrismaTicketRepository implements ITicketRepository {
  constructor(private prisma: PrismaService) {}

  private mapTicketToEntity(t: PrismaTicket & { comments?: PrismaTicketComment[] }): TicketEntity {
    return new TicketEntity({
      id: t.id,
      ticketNumber: t.ticketNumber,
      title: t.title,
      description: t.description,
      status: t.status,
      priority: t.priority,
      lastUpdateMessage: t.lastUpdateMessage,
      userId: t.userId,
      plantId: t.plantId,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
      comments: t.comments?.map(
        c =>
          new TicketCommentEntity({
            id: c.id,
            ticketId: c.ticketId,
            userId: c.userId,
            message: c.message,
            createdAt: c.createdAt,
          }),
      ),
    });
  }

  private mapCommentToEntity(c: PrismaTicketComment): TicketCommentEntity {
    return new TicketCommentEntity({
      id: c.id,
      ticketId: c.ticketId,
      userId: c.userId,
      message: c.message,
      createdAt: c.createdAt,
    });
  }

  async findById(id: string): Promise<TicketEntity | null> {
    const t = await this.prisma.ticket.findUnique({
      where: { id },
      include: { comments: true },
    });
    return t ? this.mapTicketToEntity(t) : null;
  }

  async findAll(page = 1, limit = 100): Promise<TicketEntity[]> {
    const skip = (page - 1) * limit;
    const tickets = await this.prisma.ticket.findMany({
      skip,
      take: limit,
      include: { comments: true },
      orderBy: { updatedAt: 'desc' },
    });
    return tickets.map(t => this.mapTicketToEntity(t));
  }

  async findAllByUserId(userId: string, page = 1, limit = 100): Promise<TicketEntity[]> {
    const skip = (page - 1) * limit;
    const tickets = await this.prisma.ticket.findMany({
      where: { userId },
      skip,
      take: limit,
      include: { comments: true },
      orderBy: { updatedAt: 'desc' },
    });
    return tickets.map(t => this.mapTicketToEntity(t));
  }

  async create(userId: string, ticket: Partial<TicketEntity>): Promise<TicketEntity> {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ticketNumber = `TKT-${uniqueSuffix}`;

    const created = await this.prisma.ticket.create({
      data: {
        ticketNumber,
        title: ticket.title!,
        description: ticket.description!,
        status: ticket.status || 'OPEN',
        priority: ticket.priority || 'MEDIUM',
        userId,
        plantId: ticket.plantId!,
        lastUpdateMessage: 'Ticket raised successfully.',
      },
    });
    return this.mapTicketToEntity(created);
  }

  async update(id: string, ticket: Partial<TicketEntity>): Promise<TicketEntity> {
    const updated = await this.prisma.ticket.update({
      where: { id },
      data: {
        title: ticket.title,
        description: ticket.description,
        status: ticket.status,
        priority: ticket.priority,
        lastUpdateMessage: ticket.lastUpdateMessage,
      },
    });
    return this.mapTicketToEntity(updated);
  }

  async delete(id: string): Promise<boolean> {
    await this.prisma.ticket.delete({ where: { id } });
    return true;
  }

  // Comments
  async findCommentsByTicketId(ticketId: string): Promise<TicketCommentEntity[]> {
    const comments = await this.prisma.ticketComment.findMany({
      where: { ticketId },
      orderBy: { createdAt: 'asc' },
    });
    return comments.map(c => this.mapCommentToEntity(c));
  }

  async createComment(ticketId: string, userId: string, message: string): Promise<TicketCommentEntity> {
    const comment = await this.prisma.$transaction(async (tx) => {
      const c = await tx.ticketComment.create({
        data: {
          ticketId,
          userId,
          message,
        },
      });

      // Update ticket lastUpdateMessage
      await tx.ticket.update({
        where: { id: ticketId },
        data: {
          lastUpdateMessage: message.length > 50 ? `${message.substring(0, 47)}...` : message,
        },
      });

      return c;
    });

    return this.mapCommentToEntity(comment);
  }
}
