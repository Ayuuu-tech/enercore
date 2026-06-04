import { PrismaService } from '../../../common/prisma/prisma.service';
import { ITicketRepository } from '../domain/ticket.repository.interface';
import { TicketEntity, TicketCommentEntity } from '../domain/ticket.entity';
export declare class PrismaTicketRepository implements ITicketRepository {
    private prisma;
    constructor(prisma: PrismaService);
    private mapTicketToEntity;
    private mapCommentToEntity;
    findById(id: string): Promise<TicketEntity | null>;
    findAll(): Promise<TicketEntity[]>;
    findAllByUserId(userId: string): Promise<TicketEntity[]>;
    create(userId: string, ticket: Partial<TicketEntity>): Promise<TicketEntity>;
    update(id: string, ticket: Partial<TicketEntity>): Promise<TicketEntity>;
    delete(id: string): Promise<boolean>;
    findCommentsByTicketId(ticketId: string): Promise<TicketCommentEntity[]>;
    createComment(ticketId: string, userId: string, message: string): Promise<TicketCommentEntity>;
}
