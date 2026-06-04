"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TicketEntity = exports.TicketCommentEntity = void 0;
class TicketCommentEntity {
    id;
    ticketId;
    userId;
    message;
    createdAt;
    constructor(partial) {
        Object.assign(this, partial);
    }
}
exports.TicketCommentEntity = TicketCommentEntity;
class TicketEntity {
    id;
    ticketNumber;
    title;
    description;
    status;
    priority;
    lastUpdateMessage;
    userId;
    plantId;
    createdAt;
    updatedAt;
    comments;
    constructor(partial) {
        Object.assign(this, partial);
    }
}
exports.TicketEntity = TicketEntity;
//# sourceMappingURL=ticket.entity.js.map