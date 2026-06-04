"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.VendorEntity = void 0;
class VendorEntity {
    id;
    companyName;
    rating;
    isVerified;
    createdAt;
    updatedAt;
    constructor(partial) {
        Object.assign(this, partial);
    }
}
exports.VendorEntity = VendorEntity;
//# sourceMappingURL=vendor.entity.js.map