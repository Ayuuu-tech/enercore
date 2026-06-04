import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { IVendorRepository } from '../domain/vendor.repository.interface';
import { VendorEntity } from '../domain/vendor.entity';
import { Vendor as PrismaVendor } from '@prisma/client';

@Injectable()
export class PrismaVendorRepository implements IVendorRepository {
  constructor(private prisma: PrismaService) {}

  private mapToEntity(v: PrismaVendor): VendorEntity {
    return new VendorEntity({
      id: v.id,
      companyName: v.companyName,
      rating: v.rating,
      isVerified: v.isVerified,
      createdAt: v.createdAt,
      updatedAt: v.updatedAt,
    });
  }

  async findById(id: string): Promise<VendorEntity | null> {
    const vendor = await this.prisma.vendor.findUnique({ where: { id } });
    return vendor ? this.mapToEntity(vendor) : null;
  }

  async findAll(): Promise<VendorEntity[]> {
    const vendors = await this.prisma.vendor.findMany();
    return vendors.map(v => this.mapToEntity(v));
  }

  async update(id: string, vendor: Partial<VendorEntity>): Promise<VendorEntity> {
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
}
