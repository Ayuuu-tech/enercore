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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BillingService = void 0;
const common_1 = require("@nestjs/common");
const client_1 = require("@prisma/client");
let BillingService = class BillingService {
    invoiceRepository;
    constructor(invoiceRepository) {
        this.invoiceRepository = invoiceRepository;
    }
    async findById(id) {
        const invoice = await this.invoiceRepository.findById(id);
        if (!invoice) {
            throw new common_1.NotFoundException(`Invoice with ID ${id} not found`);
        }
        return invoice;
    }
    async findAll() {
        return this.invoiceRepository.findAll();
    }
    async findAllByUser(userId) {
        return this.invoiceRepository.findAllByUserId(userId);
    }
    async create(dto) {
        if (!dto.invoiceNumber) {
            const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
            dto.invoiceNumber = `INV-${uniqueSuffix}`;
        }
        return this.invoiceRepository.create(dto);
    }
    async payInvoice(id) {
        const invoice = await this.findById(id);
        return this.invoiceRepository.update(id, {
            status: client_1.InvoiceStatus.PAID,
            paidAt: new Date(),
        });
    }
    async delete(id) {
        await this.findById(id);
        return this.invoiceRepository.delete(id);
    }
};
exports.BillingService = BillingService;
exports.BillingService = BillingService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, common_1.Inject)('IInvoiceRepository')),
    __metadata("design:paramtypes", [Object])
], BillingService);
//# sourceMappingURL=billing.service.js.map