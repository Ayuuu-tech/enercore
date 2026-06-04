import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { IProductRepository } from '../domain/product.repository.interface';
import { ProductEntity } from '../domain/product.entity';

@Injectable()
export class MarketplaceService {
  constructor(
    @Inject('IProductRepository')
    private readonly productRepository: IProductRepository,
  ) {}

  async findById(id: string): Promise<ProductEntity> {
    const product = await this.productRepository.findById(id);
    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }
    return product;
  }

  async findAll(filters: { category?: string; search?: string; vendorId?: string }): Promise<ProductEntity[]> {
    return this.productRepository.findAll(filters);
  }

  async create(dto: Partial<ProductEntity>): Promise<ProductEntity> {
    return this.productRepository.create(dto);
  }

  async update(id: string, dto: Partial<ProductEntity>): Promise<ProductEntity> {
    await this.findById(id);
    return this.productRepository.update(id, dto);
  }

  async delete(id: string): Promise<boolean> {
    await this.findById(id);
    return this.productRepository.delete(id);
  }
}
