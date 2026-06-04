import { PrismaService } from '../../../common/prisma/prisma.service';
import { IProductRepository } from '../domain/product.repository.interface';
import { ProductEntity } from '../domain/product.entity';
export declare class PrismaProductRepository implements IProductRepository {
    private prisma;
    constructor(prisma: PrismaService);
    private mapToEntity;
    findById(id: string): Promise<ProductEntity | null>;
    findAll(filters: {
        category?: string;
        search?: string;
        vendorId?: string;
    }): Promise<ProductEntity[]>;
    create(p: Partial<ProductEntity>): Promise<ProductEntity>;
    update(id: string, p: Partial<ProductEntity>): Promise<ProductEntity>;
    delete(id: string): Promise<boolean>;
}
