import { IVendorRepository } from '../domain/vendor.repository.interface';
import { VendorEntity } from '../domain/vendor.entity';
export declare class VendorsService {
    private readonly vendorRepository;
    constructor(vendorRepository: IVendorRepository);
    findById(id: string): Promise<VendorEntity>;
    findAll(): Promise<VendorEntity[]>;
    update(id: string, dto: Partial<VendorEntity>): Promise<VendorEntity>;
    verifyVendor(id: string, isVerified: boolean): Promise<VendorEntity>;
}
