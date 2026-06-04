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
exports.PrismaVendorRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../../common/prisma/prisma.service");
const vendor_entity_1 = require("../domain/vendor.entity");
let PrismaVendorRepository = class PrismaVendorRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    mapToEntity(v) {
        return new vendor_entity_1.VendorEntity({
            id: v.id,
            companyName: v.companyName,
            rating: v.rating,
            isVerified: v.isVerified,
            createdAt: v.createdAt,
            updatedAt: v.updatedAt,
        });
    }
    async findById(id) {
        const vendor = await this.prisma.vendor.findUnique({ where: { id } });
        return vendor ? this.mapToEntity(vendor) : null;
    }
    async findAll() {
        const vendors = await this.prisma.vendor.findMany();
        return vendors.map(v => this.mapToEntity(v));
    }
    async update(id, vendor) {
        const updated = await this.prisma.vendor.update({
            where: { id },
            data: {
                companyName: vendor.companyName,
                rating: vendor.rating,
                isVerified: vendor.isVerified,
            },
        });
        return this.mapToEntity(updated);
    }
};
exports.PrismaVendorRepository = PrismaVendorRepository;
exports.PrismaVendorRepository = PrismaVendorRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PrismaVendorRepository);
//# sourceMappingURL=prisma-vendor.repository.js.map