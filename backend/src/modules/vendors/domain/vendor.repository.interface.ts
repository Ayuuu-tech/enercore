import { VendorEntity } from './vendor.entity';

export interface IVendorRepository {
  findById(id: string): Promise<VendorEntity | null>;
  findAll(): Promise<VendorEntity[]>;
  update(id: string, vendor: Partial<VendorEntity>): Promise<VendorEntity>;
}
