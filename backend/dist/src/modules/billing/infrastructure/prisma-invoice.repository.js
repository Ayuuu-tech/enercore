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
exports.PrismaInvoiceRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../../common/prisma/prisma.service");
const invoice_entity_1 = require("../domain/invoice.entity");
let PrismaInvoiceRepository = class PrismaInvoiceRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    mapToEntity(i) {
        return new invoice_entity_1.InvoiceEntity({
            id: i.id,
            invoiceNumber: i.invoiceNumber,
            amount: i.amount,
            period: i.period,
            status: i.status,
            dueDate: i.dueDate,
            paidAt: i.paidAt,
            userId: i.userId,
            plantId: i.plantId,
            createdAt: i.createdAt,
            updatedAt: i.updatedAt,
        });
    }
    async findById(id) {
        const invoice = await this.prisma.invoice.findUnique({ where: { id } });
        return invoice ? this.mapToEntity(invoice) : null;
    }
    async findAll() {
        const invoices = await this.prisma.invoice.findMany({
            orderBy: { createdAt: 'desc' },
        });
        return invoices.map(i => this.mapToEntity(i));
    }
    async findAllByUserId(userId) {
        const invoices = await this.prisma.invoice.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });
        return invoices.map(i => this.mapToEntity(i));
    }
    async create(invoice) {
        const created = await this.prisma.invoice.create({
            data: {
                invoiceNumber: invoice.invoiceNumber,
                amount: invoice.amount,
                period: invoice.period,
                status: invoice.status || 'PENDING',
                dueDate: invoice.dueDate,
                userId: invoice.userId,
                plantId: invoice.plantId || null,
            },
        });
        return this.mapToEntity(created);
    }
    async update(id, invoice) {
        const updated = await this.prisma.invoice.update({
            where: { id },
            data: {
                amount: invoice.amount,
                period: invoice.period,
                status: invoice.status,
                dueDate: invoice.dueDate,
                paidAt: invoice.paidAt,
            },
        });
        return this.mapToEntity(updated);
    }
    async delete(id) {
        await this.prisma.invoice.delete({ where: { id } });
        return true;
    }
};
exports.PrismaInvoiceRepository = PrismaInvoiceRepository;
exports.PrismaInvoiceRepository = PrismaInvoiceRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PrismaInvoiceRepository);
//# sourceMappingURL=prisma-invoice.repository.js.map