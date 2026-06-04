import { PrismaService } from '../../../common/prisma/prisma.service';
import { IVendorRepository } from '../domain/vendor.repository.interface';
import { VendorEntity } from '../domain/vendor.entity';
export declare class PrismaVendorRepository implements IVendorRepository {
    private prisma;
    constructor(prisma: PrismaService);
    private mapToEntity;
    findById(id: string): Promise<VendorEntity | null>;
    findAll(): Promise<VendorEntity[]>;
    update(id: string, vendor: Partial<VendorEntity>): Promise<VendorEntity>;
}
