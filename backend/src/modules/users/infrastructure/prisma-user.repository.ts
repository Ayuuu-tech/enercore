import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { UserEntity } from '../domain/user.entity';
import { IUserRepository } from '../domain/user.repository.interface';
import { User as PrismaUser } from '@prisma/client';

@Injectable()
export class PrismaUserRepository implements IUserRepository {
  constructor(private prisma: PrismaService) {}

  private mapToEntity(prismaUser: PrismaUser): UserEntity {
    return new UserEntity({
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

  async findById(id: string): Promise<UserEntity | null> {
    const user = await this.prisma.user.findUnique({ where: { id } });
    return user ? this.mapToEntity(user) : null;
  }

  async findByEmail(email: string): Promise<UserEntity | null> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    return user ? this.mapToEntity(user) : null;
  }

  async create(user: Partial<UserEntity>): Promise<UserEntity> {
    const created = await this.prisma.user.create({
      data: {
        email: user.email!,
        password: user.password!,
        name: user.name!,
        role: user.role,
      },
    });
    return this.mapToEntity(created);
  }

  async update(id: string, user: Partial<UserEntity>): Promise<UserEntity> {
    const data: any = {};
    if (user.email !== undefined) data.email = user.email;
    if (user.password !== undefined) data.password = user.password;
    if (user.name !== undefined) data.name = user.name;
    if (user.role !== undefined) data.role = user.role;
    if (user.phone !== undefined) data.phone = user.phone;
    if (user.company !== undefined) data.company = user.company;
    if (user.gstNumber !== undefined) data.gstNumber = user.gstNumber;
    if (user.postalCode !== undefined) data.postalCode = user.postalCode;
    if (user.address !== undefined) data.address = user.address;
    if (user.avatarUrl !== undefined) data.avatarUrl = user.avatarUrl;

    const updated = await this.prisma.user.update({
      where: { id },
      data,
    });
    return this.mapToEntity(updated);
  }

  async delete(id: string): Promise<boolean> {
    await this.prisma.user.delete({ where: { id } });
    return true;
  }

  async findAll(): Promise<UserEntity[]> {
    const users = await this.prisma.user.findMany();
    return users.map(user => this.mapToEntity(user));
  }
}
