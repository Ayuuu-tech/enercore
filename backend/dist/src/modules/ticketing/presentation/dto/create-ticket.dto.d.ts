import { TicketPriority } from '@prisma/client';
export declare class CreateTicketDto {
    title: string;
    description: string;
    plantId: string;
    priority?: TicketPriority;
}
