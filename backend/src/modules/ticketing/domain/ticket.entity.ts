import { TicketPriority, TicketStatus } from '@prisma/client';

export class TicketCommentEntity {
  id: string;
  ticketId: string;
  userId: string;
  message: string;
  createdAt: Date;

  constructor(partial: Partial<TicketCommentEntity>) {
    Object.assign(this, partial);
  }
}

export class TicketEntity {
  id: string;
  ticketNumber: string;
  title: string;
  description: string;
  status: TicketStatus;
  priority: TicketPriority;
  lastUpdateMessage?: string | null;
  userId: string;
  plantId: string;
  createdAt: Date;
  updatedAt: Date;
  comments?: TicketCommentEntity[];

  constructor(partial: Partial<TicketEntity>) {
    Object.assign(this, partial);
  }
}
