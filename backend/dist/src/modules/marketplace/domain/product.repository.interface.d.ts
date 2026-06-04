import { ProductEntity } from './product.entity';
export interface IProductRepository {
    findById(id: string): Promise<ProductEntity | null>;
    findAll(filters: {
        category?: string;
        search?: string;
        vendorId?: string;
    }): Promise<ProductEntity[]>;
    create(product: Partial<ProductEntity>): Promise<ProductEntity>;
    update(id: string, product: Partial<ProductEntity>): Promise<ProductEntity>;
    delete(id: string): Promise<boolean>;
}
