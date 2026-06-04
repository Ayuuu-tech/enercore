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
exports.PrismaOrderRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../../common/prisma/prisma.service");
const order_entity_1 = require("../domain/order.entity");
const client_1 = require("@prisma/client");
let PrismaOrderRepository = class PrismaOrderRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    mapToEntity(o) {
        return new order_entity_1.OrderEntity({
            id: o.id,
            orderNumber: o.orderNumber,
            totalAmount: o.totalAmount,
            status: o.status,
            userId: o.userId,
            createdAt: o.createdAt,
            updatedAt: o.updatedAt,
            items: o.items?.map(i => new order_entity_1.OrderItemEntity({
                id: i.id,
                orderId: i.orderId,
                productId: i.productId,
                quantity: i.quantity,
                priceAtPurchase: i.priceAtPurchase,
            })),
        });
    }
    async findById(id) {
        const order = await this.prisma.order.findUnique({
            where: { id },
            include: { items: true },
        });
        return order ? this.mapToEntity(order) : null;
    }
    async findAll() {
        const orders = await this.prisma.order.findMany({
            include: { items: true },
            orderBy: { createdAt: 'desc' },
        });
        return orders.map(o => this.mapToEntity(o));
    }
    async findAllByUserId(userId) {
        const orders = await this.prisma.order.findMany({
            where: { userId },
            include: { items: true },
            orderBy: { createdAt: 'desc' },
        });
        return orders.map(o => this.mapToEntity(o));
    }
    async create(userId, items) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        const orderNumber = `ORD-${uniqueSuffix}`;
        const order = await this.prisma.$transaction(async (tx) => {
            let totalAmount = 0;
            const orderItemsToCreate = [];
            for (const item of items) {
                const product = await tx.product.findUnique({
                    where: { id: item.productId },
                });
                if (!product) {
                    throw new common_1.NotFoundException(`Product with ID ${item.productId} not found`);
                }
                if (product.stock < item.quantity) {
                    throw new common_1.BadRequestException(`Insufficient stock for product "${product.title}". Available: ${product.stock}, Requested: ${item.quantity}`);
                }
                await tx.product.update({
                    where: { id: item.productId },
                    data: { stock: product.stock - item.quantity },
                });
                const priceAtPurchase = product.price;
                totalAmount += priceAtPurchase * item.quantity;
                orderItemsToCreate.push({
                    productId: item.productId,
                    quantity: item.quantity,
                    priceAtPurchase,
                });
            }
            const newOrder = await tx.order.create({
                data: {
                    orderNumber,
                    totalAmount,
                    userId,
                    status: client_1.OrderStatus.PENDING,
                    items: {
                        create: orderItemsToCreate,
                    },
                },
                include: { items: true },
            });
            return newOrder;
        });
        return this.mapToEntity(order);
    }
    async updateStatus(id, status) {
        const updated = await this.prisma.order.update({
            where: { id },
            data: { status },
            include: { items: true },
        });
        return this.mapToEntity(updated);
    }
};
exports.PrismaOrderRepository = PrismaOrderRepository;
exports.PrismaOrderRepository = PrismaOrderRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PrismaOrderRepository);
//# sourceMappingURL=prisma-order.repository.js.map