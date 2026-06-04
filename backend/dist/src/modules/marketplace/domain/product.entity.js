"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProductEntity = void 0;
class ProductEntity {
    id;
    title;
    brand;
    spec;
    rating;
    reviewsCount;
    price;
    originalPrice;
    isAssured;
    category;
    stock;
    vendorId;
    createdAt;
    updatedAt;
    constructor(partial) {
        Object.assign(this, partial);
    }
}
exports.ProductEntity = ProductEntity;
//# sourceMappingURL=product.entity.js.map