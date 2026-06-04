import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async getSystemStats() {
    const totalUsers = await this.prisma.user.count();
    const totalPlants = await this.prisma.plant.count();
    const totalPanels = await this.prisma.panel.count();
    const openTickets = await this.prisma.ticket.count({ where: { status: 'OPEN' } });
    const totalProducts = await this.prisma.product.count();

    const revenueAggregation = await this.prisma.invoice.aggregate({
      where: { status: 'PAID' },
      _sum: { amount: true },
    });

    return {
      usersCount: totalUsers,
      plantsCount: totalPlants,
      panelsCount: totalPanels,
      openTicketsCount: openTickets,
      productsCount: totalProducts,
      totalRevenue: revenueAggregation._sum.amount || 0,
    };
  }

  async getUnverifiedVendors() {
    return this.prisma.vendor.findMany({
      where: { isVerified: false },
      include: {
        user: {
          select: {
            name: true,
            email: true,
          },
        },
      },
    });
  }
}
