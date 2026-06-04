import { VendorsService } from '../application/vendors.service';
import { UserEntity } from '../../users/domain/user.entity';
export declare class VendorsController {
    private readonly vendorsService;
    constructor(vendorsService: VendorsService);
    findAll(): Promise<import("../domain/vendor.entity").VendorEntity[]>;
    findOne(id: string): Promise<import("../domain/vendor.entity").VendorEntity>;
    updateMe(user: UserEntity, body: {
        companyName?: string;
    }): Promise<import("../domain/vendor.entity").VendorEntity>;
    verify(id: string, body: {
        isVerified: boolean;
    }): Promise<import("../domain/vendor.entity").VendorEntity>;
}
