import { PrismaService } from '../../../common/prisma/prisma.service';
export declare class AdminService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getSystemStats(): Promise<{
        usersCount: number;
        plantsCount: number;
        panelsCount: number;
        openTicketsCount: number;
        productsCount: number;
        totalRevenue: number;
    }>;
    getUnverifiedVendors(): Promise<({
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
