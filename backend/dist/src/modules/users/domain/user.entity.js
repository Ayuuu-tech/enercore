"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserEntity = void 0;
class UserEntity {
    id;
    email;
    password;
    name;
    role;
    phone;
    company;
    gstNumber;
    postalCode;
    address;
    avatarUrl;
    createdAt;
    updatedAt;
    constructor(partial) {
        Object.assign(this, partial);
    }
}
exports.UserEntity = UserEntity;
//# sourceMappingURL=user.entity.js.map