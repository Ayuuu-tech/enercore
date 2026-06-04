"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationEntity = void 0;
class NotificationEntity {
    id;
    userId;
    title;
    message;
    read;
    createdAt;
    constructor(partial) {
        Object.assign(this, partial);
    }
}
exports.NotificationEntity = NotificationEntity;
//# sourceMappingURL=notification.entity.js.map