import { ITicketRepository } from '../domain/ticket.repository.interface';
import { TicketEntity, TicketCommentEntity } from '../domain/ticket.entity';
export declare class TicketingService {
    private readonly ticketRepository;
    constructor(ticketRepository: ITicketRepository);
    findById(id: string): Promise<TicketEntity>;
    findAll(): Promise<TicketEntity[]>;
    findAllByUser(userId: string): Promise<TicketEntity[]>;
    createTicket(userId: string, dto: Partial<TicketEntity>): Promise<TicketEntity>;
    updateTicket(id: string, dto: Partial<TicketEntity>): Promise<TicketEntity>;
    deleteTicket(id: string): Promise<boolean>;
    getComments(ticketId: string): Promise<TicketCommentEntity[]>;
    addComment(ticketId: string, userId: string, message: string): Promise<TicketCommentEntity>;
}
