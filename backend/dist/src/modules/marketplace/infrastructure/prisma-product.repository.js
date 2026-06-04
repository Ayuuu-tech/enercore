"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PrismaProductRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../../common/prisma/prisma.service");
const product_entity_1 = require("../domain/product.entity");
let PrismaProductRepository = class PrismaProductRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    mapToEntity(p) {
        return new product_entity_1.ProductEntity({
            id: p.id,
            title: p.title,
            brand: p.brand,
            spec: p.spec,
            rating: p.rating,
            reviewsCount: p.reviewsCount,
            price: p.price,
            originalPrice: p.originalPrice,
            isAssured: p.isAssured,
            category: p.category,
            stock: p.stock,
            vendorId: p.vendorId,
            createdAt: p.createdAt,
            updatedAt: p.updatedAt,
        });
    }
    async findById(id) {
        const product = await this.prisma.product.findUnique({ where: { id } });
        return product ? this.mapToEntity(product) : null;
    }
    async findAll(filters) {
        const where = {};
        if (filters.category && filters.category !== 'All') {
            where.category = {
                equals: filters.category,
                mode: 'insensitive',
            };
        }
        if (filters.vendorId) {
            where.vendorId = filters.vendorId;
        }
        if (filters.search) {
            where.OR = [
                { title: { contains: filters.search, mode: 'insensitive' } },
                { brand: { contains: filters.search, mode: 'insensitive' } },
                { spec: { contains: filters.search, mode: 'insensitive' } },
            ];
        }
        const products = await this.prisma.product.findMany({ where });
        return products.map(p => this.mapToEntity(p));
    }
    async create(p) {
        const created = await this.prisma.product.create({
            data: {
                title: p.title,
                brand: p.brand,
                spec: p.spec,
                price: p.price,
                originalPrice: p.originalPrice,
                isAssured: p.isAssured || false,
                category: p.category,
                stock: p.stock || 0,
                vendorId: p.vendorId,
            },
        });
        return this.mapToEntity(created);
    }
    async update(id, p) {
        const updated = await this.prisma.product.update({
            where: { id },
            data: {
                title: p.title,
                brand: p.brand,
                spec: p.spec,
                price: p.price,
                originalPrice: p.originalPrice,
                isAssured: p.isAssured,
                category: p.category,
                stock: p.stock,
            },
        });
        return this.mapToEntity(updated);
    }
    async delete(id) {
        await this.prisma.product.delete({ where: { id } });
        return true;
    }
};
exports.PrismaProductRepository = PrismaProductRepository;
exports.PrismaProductRepository = PrismaProductRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PrismaProductRepository);
//# sourceMappingURL=prisma-product.repository.js.map