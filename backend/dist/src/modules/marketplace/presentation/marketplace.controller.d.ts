import { MarketplaceService } from '../application/marketplace.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UserEntity } from '../../users/domain/user.entity';
export declare class MarketplaceController {
    private readonly marketplaceService;
    constructor(marketplaceService: MarketplaceService);
    findAll(category?: string, search?: string, vendorId?: string): Promise<import("../domain/product.entity").ProductEntity[]>;
    findOne(id: string): Promise<import("../domain/product.entity").ProductEntity>;
    create(dto: CreateProductDto, user: UserEntity): Promise<import("../domain/product.entity").ProductEntity>;
    update(id: string, dto: Partial<CreateProductDto>, user: UserEntity): Promise<import("../domain/product.entity").ProductEntity>;
    remove(id: string, user: UserEntity): Promise<boolean>;
}
