"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrderEntity = exports.OrderItemEntity = void 0;
class OrderItemEntity {
    id;
    orderId;
    productId;
    quantity;
    priceAtPurchase;
    constructor(partial) {
        Object.assign(this, partial);
    }
}
exports.OrderItemEntity = OrderItemEntity;
class OrderEntity {
    id;
    orderNumber;
    totalAmount;
    status;
    userId;
    createdAt;
    updatedAt;
    items;
    constructor(partial) {
        Object.assign(this, partial);
    }
}
exports.OrderEntity = OrderEntity;
//# sourceMappingURL=order.entity.js.map