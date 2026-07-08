import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { IVendorRepository } from '../domain/vendor.repository.interface';
import { VendorEntity } from '../domain/vendor.entity';
import { PrismaService } from '../../../common/prisma/prisma.service';

@Injectable()
export class VendorsService {
  constructor(
    @Inject('IVendorRepository')
    private readonly vendorRepository: IVendorRepository,
    private readonly prisma: PrismaService,
  ) {}

  async findById(id: string): Promise<VendorEntity> {
    const vendor = await this.vendorRepository.findById(id);
    if (!vendor) {
      throw new NotFoundException(`Vendor profile with ID ${id} not found`);
    }
    return vendor;
  }

  async findAll(): Promise<VendorEntity[]> {
    return this.vendorRepository.findAll();
  }

  async update(id: string, dto: Partial<VendorEntity>): Promise<VendorEntity> {
    await this.findById(id);
    return this.vendorRepository.update(id, dto);
  }

  async verifyVendor(id: string, isVerified: boolean): Promise<VendorEntity> {
    await this.findById(id);
    return this.vendorRepository.update(id, { isVerified });
  }

  async getStats(vendorId: string) {
    const pendingOrders = await this.prisma.order.count({
      where: {
        items: { some: { product: { vendorId } } },
        status: 'PENDING',
      },
    });

    const totalProducts = await this.prisma.product.count({
      where: { vendorId },
    });

    const outOfStock = await this.prisma.product.count({
      where: { vendorId, stock: 0 },
    });

    const revenueAgg = await this.prisma.order.aggregate({
      where: {
        items: { some: { product: { vendorId } } },
        status: 'DELIVERED',
      },
      _sum: { totalAmount: true },
    });

    return {
      pendingOrders,
      outOfStock,
      totalProducts,
      monthlyRevenue: revenueAgg._sum.totalAmount || 0,
    };
  }
}
