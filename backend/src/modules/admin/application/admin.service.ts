import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PaymentStatus, Role, SubscriptionPlan, SubscriptionStatus } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { PlantAccessService } from '../../../common/access/plant-access.service';
import { addPeriod, effectiveStatus } from './subscription.util';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly plantAccess: PlantAccessService,
  ) {}

  // ── User management ────────────────────────────────────────────────────────

  async listUsers() {
    const users = await this.prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        _count: { select: { plants: true, plantAccess: true } },
      },
    });
    return users.map((u) => ({
      id: u.id,
      name: u.name,
      email: u.email,
      role: u.role,
      isActive: u.isActive,
      modules: u.modules,
      phone: u.phone,
      company: u.company,
      createdAt: u.createdAt,
      ownedPlants: u._count.plants,
      grantedPlants: u._count.plantAccess,
    }));
  }

  async createUser(dto: {
    email: string;
    password: string;
    name: string;
    role?: Role;
    phone?: string;
  }) {
    if (!dto.email || !dto.password || !dto.name) {
      throw new BadRequestException('email, password and name are required');
    }
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException('A user with this email already exists');
    }
    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        password: passwordHash,
        name: dto.name,
        role: dto.role ?? Role.CLIENT,
        phone: dto.phone,
      },
    });
    return { id: user.id, name: user.name, email: user.email, role: user.role, isActive: user.isActive };
  }

  async setUserActive(userId: string, isActive: boolean) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    await this.prisma.user.update({ where: { id: userId }, data: { isActive } });
    return { id: userId, isActive };
  }

  async updateUserRole(userId: string, role: Role) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    await this.prisma.user.update({ where: { id: userId }, data: { role } });
    return { id: userId, role };
  }

  async getUserModules(userId: string): Promise<string[]> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { modules: true } });
    if (!user) throw new NotFoundException('User not found');
    return user.modules;
  }

  /** Empty list = access to all modules (default). */
  async setUserModules(userId: string, modules: string[]) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    await this.prisma.user.update({ where: { id: userId }, data: { modules } });
    return { id: userId, modules };
  }

  // ── Plant assignment ───────────────────────────────────────────────────────

  async getUserPlants(userId: string) {
    return this.plantAccess.getUserPlants(userId);
  }

  async setUserPlants(userId: string, plantIds: string[]) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    await this.plantAccess.setUserPlants(userId, plantIds);
    return this.plantAccess.getUserPlants(userId);
  }

  async assignPlant(userId: string, plantId: string) {
    await this.plantAccess.assignPlant(userId, plantId);
    return { userId, plantId, assigned: true };
  }

  async revokePlant(userId: string, plantId: string) {
    await this.plantAccess.revokePlant(userId, plantId);
    return { userId, plantId, assigned: false };
  }

  async getPlantUsers(plantId: string) {
    return this.plantAccess.getPlantUsers(plantId);
  }

  /** All plants with owner info and access counts, for admin plant management. */
  async listPlantsWithAccess() {
    const plants = await this.prisma.plant.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        _count: { select: { accessGrants: true } },
      },
    });
    return plants.map((p) => ({
      id: p.id,
      name: p.name,
      location: p.location,
      peakCapacity: p.peakCapacity,
      status: p.status,
      ownerId: p.ownerId,
      ownerName: p.owner.name,
      ownerEmail: p.owner.email,
      grantedUsers: p._count.accessGrants,
    }));
  }

  async transferOwnership(plantId: string, newOwnerId: string) {
    const [plant, newOwner] = await Promise.all([
      this.prisma.plant.findUnique({ where: { id: plantId } }),
      this.prisma.user.findUnique({ where: { id: newOwnerId } }),
    ]);
    if (!plant) throw new NotFoundException('Plant not found');
    if (!newOwner) throw new NotFoundException('New owner not found');
    // Remove any redundant access grant for the new owner (they now own it).
    await this.prisma.$transaction([
      this.prisma.plant.update({ where: { id: plantId }, data: { ownerId: newOwnerId } }),
      this.prisma.plantAccess.deleteMany({ where: { plantId, userId: newOwnerId } }),
    ]);
    return { plantId, ownerId: newOwnerId };
  }

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

  // ── Subscriptions ──────────────────────────────────────────────────────────

  async listSubscriptions() {
    const subs = await this.prisma.subscription.findMany({
      orderBy: { createdAt: 'desc' },
      include: { user: { select: { id: true, name: true, email: true, isActive: true } } },
    });
    return subs.map((s) => ({
      id: s.id,
      userId: s.userId,
      userName: s.user.name,
      userEmail: s.user.email,
      plan: s.plan,
      status: effectiveStatus(s.status, s.expiryDate),
      rawStatus: s.status,
      amount: s.amount,
      startDate: s.startDate,
      expiryDate: s.expiryDate,
      createdAt: s.createdAt,
    }));
  }

  async createSubscription(dto: {
    userId: string;
    plan: SubscriptionPlan;
    amount: number;
    startDate?: string;
    activate?: boolean;
  }) {
    const user = await this.prisma.user.findUnique({ where: { id: dto.userId } });
    if (!user) throw new NotFoundException('User not found');
    const start = dto.startDate ? new Date(dto.startDate) : new Date();
    const expiry = addPeriod(start, dto.plan);
    return this.prisma.subscription.create({
      data: {
        userId: dto.userId,
        plan: dto.plan,
        amount: dto.amount ?? 0,
        startDate: start,
        expiryDate: expiry,
        status: dto.activate ? SubscriptionStatus.ACTIVE : SubscriptionStatus.PENDING,
      },
    });
  }

  async setSubscriptionStatus(id: string, status: SubscriptionStatus) {
    const sub = await this.prisma.subscription.findUnique({ where: { id } });
    if (!sub) throw new NotFoundException('Subscription not found');
    return this.prisma.subscription.update({ where: { id }, data: { status } });
  }

  /** Extend expiry by one plan period and mark ACTIVE. */
  async renewSubscription(id: string) {
    const sub = await this.prisma.subscription.findUnique({ where: { id } });
    if (!sub) throw new NotFoundException('Subscription not found');
    // Renew from whichever is later: now or current expiry.
    const base = sub.expiryDate.getTime() > Date.now() ? sub.expiryDate : new Date();
    const expiry = addPeriod(base, sub.plan);
    return this.prisma.subscription.update({
      where: { id },
      data: { status: SubscriptionStatus.ACTIVE, expiryDate: expiry },
    });
  }

  // ── Payments ───────────────────────────────────────────────────────────────

  async listPayments() {
    const payments = await this.prisma.payment.findMany({
      orderBy: { createdAt: 'desc' },
      include: { user: { select: { name: true, email: true } } },
    });
    return payments.map((p) => ({
      id: p.id,
      userId: p.userId,
      userName: p.user.name,
      userEmail: p.user.email,
      subscriptionId: p.subscriptionId,
      amount: p.amount,
      status: p.status,
      method: p.method,
      reference: p.reference,
      paidAt: p.paidAt,
      createdAt: p.createdAt,
    }));
  }

  async recordPayment(dto: {
    userId: string;
    amount: number;
    status?: PaymentStatus;
    method?: string;
    reference?: string;
    subscriptionId?: string;
  }) {
    const user = await this.prisma.user.findUnique({ where: { id: dto.userId } });
    if (!user) throw new NotFoundException('User not found');
    const status = dto.status ?? PaymentStatus.SUCCESS;
    return this.prisma.payment.create({
      data: {
        userId: dto.userId,
        amount: dto.amount,
        status,
        method: dto.method,
        reference: dto.reference,
        subscriptionId: dto.subscriptionId,
        paidAt: status === PaymentStatus.SUCCESS ? new Date() : null,
      },
    });
  }

  async updatePaymentStatus(id: string, status: PaymentStatus) {
    const payment = await this.prisma.payment.findUnique({ where: { id } });
    if (!payment) throw new NotFoundException('Payment not found');
    return this.prisma.payment.update({
      where: { id },
      data: { status, paidAt: status === PaymentStatus.SUCCESS ? new Date() : payment.paidAt },
    });
  }

  // ── Analytics dashboard ──────────────────────────────────────────────────────

  async getUserAnalytics() {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const [
      totalUsers,
      activeUsers,
      subs,
      recentUsers,
      revenueAll,
      revenueMonth,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { isActive: true } }),
      this.prisma.subscription.findMany({
        include: { user: { select: { name: true, email: true } } },
      }),
      this.prisma.user.findMany({
        orderBy: { createdAt: 'desc' },
        take: 5,
        select: { id: true, name: true, email: true, role: true, createdAt: true, isActive: true },
      }),
      this.prisma.payment.aggregate({ where: { status: PaymentStatus.SUCCESS }, _sum: { amount: true } }),
      this.prisma.payment.aggregate({
        where: { status: PaymentStatus.SUCCESS, paidAt: { gte: monthStart } },
        _sum: { amount: true },
      }),
    ]);

    let activeSubscriptions = 0;
    let expiredSubscriptions = 0;
    let pendingSubscriptions = 0;
    for (const s of subs) {
      const eff = effectiveStatus(s.status, s.expiryDate);
      if (eff === SubscriptionStatus.ACTIVE) activeSubscriptions++;
      else if (eff === SubscriptionStatus.EXPIRED) expiredSubscriptions++;
      else if (eff === SubscriptionStatus.PENDING) pendingSubscriptions++;
    }

    // Recently expired (within last 30 days)
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const recentlyExpired = subs
      .filter((s) => s.expiryDate < now && s.expiryDate > thirtyDaysAgo)
      .sort((a, b) => b.expiryDate.getTime() - a.expiryDate.getTime())
      .slice(0, 5)
      .map((s) => ({
        id: s.id,
        userName: s.user.name,
        userEmail: s.user.email,
        plan: s.plan,
        expiryDate: s.expiryDate,
      }));

    return {
      totalUsers,
      activeUsers,
      inactiveUsers: totalUsers - activeUsers,
      activeSubscriptions,
      expiredSubscriptions,
      pendingSubscriptions,
      totalRevenue: revenueAll._sum.amount ?? 0,
      monthlyRevenue: revenueMonth._sum.amount ?? 0,
      recentUsers,
      recentlyExpired,
    };
  }
}
