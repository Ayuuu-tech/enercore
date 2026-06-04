import { AdminService } from '../application/admin.service';
export declare class AdminController {
    private readonly adminService;
    constructor(adminService: AdminService);
    getStats(): Promise<{
        usersCount: number;
        plantsCount: number;
        panelsCount: number;
        openTicketsCount: number;
        productsCount: number;
        totalRevenue: number;
    }>;
    getPendingVendors(): Promise<({
        user: {
            email: string;
            name: string;
        };
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        companyName: string;
        rating: number;
        isVerified: boolean;
    })[]>;
}
