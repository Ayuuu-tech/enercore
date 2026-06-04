import { TicketEntity, TicketCommentEntity } from './ticket.entity';
export interface ITicketRepository {
    findById(id: string): Promise<TicketEntity | null>;
    findAll(): Promise<TicketEntity[]>;
    findAllByUserId(userId: string): Promise<TicketEntity[]>;
    create(userId: string, ticket: Partial<TicketEntity>): Promise<TicketEntity>;
    update(id: string, ticket: Partial<TicketEntity>): Promise<TicketEntity>;
    delete(id: string): Promise<boolean>;
    findCommentsByTicketId(ticketId: string): Promise<TicketCommentEntity[]>;
    createComment(ticketId: string, userId: string, message: string): Promise<TicketCommentEntity>;
}
