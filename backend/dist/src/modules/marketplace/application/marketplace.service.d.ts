import { IProductRepository } from '../domain/product.repository.interface';
import { ProductEntity } from '../domain/product.entity';
export declare class MarketplaceService {
    private readonly productRepository;
    constructor(productRepository: IProductRepository);
    findById(id: string): Promise<ProductEntity>;
    findAll(filters: {
        category?: string;
        search?: string;
        vendorId?: string;
    }): Promise<ProductEntity[]>;
    create(dto: Partial<ProductEntity>): Promise<ProductEntity>;
    update(id: string, dto: Partial<ProductEntity>): Promise<ProductEntity>;
    delete(id: string): Promise<boolean>;
}
