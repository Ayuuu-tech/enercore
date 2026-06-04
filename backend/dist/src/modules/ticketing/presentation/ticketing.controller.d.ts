import { TicketingService } from '../application/ticketing.service';
import { CreateTicketDto } from './dto/create-ticket.dto';
import { UserEntity } from '../../users/domain/user.entity';
import { TicketPriority, TicketStatus } from '@prisma/client';
export declare class TicketingController {
    private readonly ticketingService;
    constructor(ticketingService: TicketingService);
    findAll(user: UserEntity): Promise<import("../domain/ticket.entity").TicketEntity[]>;
    findOne(id: string, user: UserEntity): Promise<import("../domain/ticket.entity").TicketEntity>;
    create(dto: CreateTicketDto, user: UserEntity): Promise<import("../domain/ticket.entity").TicketEntity>;
    update(id: string, dto: {
        status?: TicketStatus;
        priority?: TicketPriority;
        lastUpdateMessage?: string;
    }, user: UserEntity): Promise<import("../domain/ticket.entity").TicketEntity>;
    remove(id: string, user: UserEntity): Promise<boolean>;
    getComments(id: string, user: UserEntity): Promise<import("../domain/ticket.entity").TicketCommentEntity[]>;
    addComment(id: string, body: {
        message: string;
    }, user: UserEntity): Promise<import("../domain/ticket.entity").TicketCommentEntity>;
}
