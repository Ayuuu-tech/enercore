"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InvoiceEntity = void 0;
class InvoiceEntity {
    id;
    invoiceNumber;
    amount;
    period;
    status;
    dueDate;
    paidAt;
    userId;
    plantId;
    createdAt;
    updatedAt;
    constructor(partial) {
        Object.assign(this, partial);
    }
}
exports.InvoiceEntity = InvoiceEntity;
//# sourceMappingURL=invoice.entity.js.map