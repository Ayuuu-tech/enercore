import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { IVendorRepository } from '../domain/vendor.repository.interface';
import { VendorEntity } from '../domain/vendor.entity';

@Injectable()
export class VendorsService {
  constructor(
    @Inject('IVendorRepository')
    private readonly vendorRepository: IVendorRepository,
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
}
