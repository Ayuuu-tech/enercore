import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { IProductRepository } from '../domain/product.repository.interface';
import { ProductEntity } from '../domain/product.entity';
import { Product as PrismaProduct } from '@prisma/client';

@Injectable()
export class PrismaProductRepository implements IProductRepository {
  constructor(private prisma: PrismaService) {}

  private mapToEntity(p: PrismaProduct): ProductEntity {
    return new ProductEntity({
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

  async findById(id: string): Promise<ProductEntity | null> {
    const product = await this.prisma.product.findUnique({ where: { id } });
    return product ? this.mapToEntity(product) : null;
  }

  async findAll(filters: { category?: string; search?: string; vendorId?: string }): Promise<ProductEntity[]> {
    const where: any = {};

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

  async create(p: Partial<ProductEntity>): Promise<ProductEntity> {
    const created = await this.prisma.product.create({
      data: {
        title: p.title!,
        brand: p.brand!,
        spec: p.spec!,
        price: p.price!,
        originalPrice: p.originalPrice,
        isAssured: p.isAssured || false,
        category: p.category!,
        stock: p.stock || 0,
        vendorId: p.vendorId!,
      },
    });
    return this.mapToEntity(created);
  }

  async update(id: string, p: Partial<ProductEntity>): Promise<ProductEntity> {
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

  async delete(id: string): Promise<boolean> {
    await this.prisma.product.delete({ where: { id } });
    return true;
  }
}
