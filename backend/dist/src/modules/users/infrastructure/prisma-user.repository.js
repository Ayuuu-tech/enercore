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
exports.PrismaUserRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../../common/prisma/prisma.service");
const user_entity_1 = require("../domain/user.entity");
let PrismaUserRepository = class PrismaUserRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    mapToEntity(prismaUser) {
        return new user_entity_1.UserEntity({
            id: prismaUser.id,
            email: prismaUser.email,
            password: prismaUser.password,
            name: prismaUser.name,
            role: prismaUser.role,
            phone: prismaUser.phone,
            company: prismaUser.company,
            gstNumber: prismaUser.gstNumber,
            postalCode: prismaUser.postalCode,
            address: prismaUser.address,
            avatarUrl: prismaUser.avatarUrl,
            createdAt: prismaUser.createdAt,
            updatedAt: prismaUser.updatedAt,
        });
    }
    async findById(id) {
        const user = await this.prisma.user.findUnique({ where: { id } });
        return user ? this.mapToEntity(user) : null;
    }
    async findByEmail(email) {
        const user = await this.prisma.user.findUnique({ where: { email } });
        return user ? this.mapToEntity(user) : null;
    }
    async create(user) {
        const created = await this.prisma.user.create({
            data: {
                email: user.email,
                password: user.password,
                name: user.name,
                role: user.role,
            },
        });
        return this.mapToEntity(created);
    }
    async update(id, user) {
        const data = {};
        if (user.email !== undefined)
            data.email = user.email;
        if (user.password !== undefined)
            data.password = user.password;
        if (user.name !== undefined)
            data.name = user.name;
        if (user.role !== undefined)
            data.role = user.role;
        if (user.phone !== undefined)
            data.phone = user.phone;
        if (user.company !== undefined)
            data.company = user.company;
        if (user.gstNumber !== undefined)
            data.gstNumber = user.gstNumber;
        if (user.postalCode !== undefined)
            data.postalCode = user.postalCode;
        if (user.address !== undefined)
            data.address = user.address;
        if (user.avatarUrl !== undefined)
            data.avatarUrl = user.avatarUrl;
        const updated = await this.prisma.user.update({
            where: { id },
            data,
        });
        return this.mapToEntity(updated);
    }
    async delete(id) {
        await this.prisma.user.delete({ where: { id } });
        return true;
    }
    async findAll() {
        const users = await this.prisma.user.findMany();
        return users.map(user => this.mapToEntity(user));
    }
};
exports.PrismaUserRepository = PrismaUserRepository;
exports.PrismaUserRepository = PrismaUserRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PrismaUserRepository);
//# sourceMappingURL=prisma-user.repository.js.map