import { ForbiddenException, Injectable } from '@nestjs/common';
import { Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { siteKeyForPlantName } from '../trackso/site-map';

export interface AccessUser {
  id: string;
  role: Role;
}

/**
 * Central authority for plant-level access control. A user can access a plant
 * if they are an ADMIN, own it, or have an explicit PlantAccess grant.
 * Every plant-scoped endpoint must funnel through this service so access
 * cannot be bypassed via direct API calls.
 */
@Injectable()
export class PlantAccessService {
  constructor(private readonly prisma: PrismaService) {}

  /** Plant IDs a user may access. Admins get every plant. */
  async getAccessiblePlantIds(user: AccessUser): Promise<string[]> {
    if (user.role === Role.ADMIN) {
      const all = await this.prisma.plant.findMany({ select: { id: true } });
      return all.map((p) => p.id);
    }
    const [owned, granted] = await Promise.all([
      this.prisma.plant.findMany({ where: { ownerId: user.id }, select: { id: true } }),
      this.prisma.plantAccess.findMany({ where: { userId: user.id }, select: { plantId: true } }),
    ]);
    const ids = new Set<string>();
    for (const p of owned) ids.add(p.id);
    for (const g of granted) ids.add(g.plantId);
    return [...ids];
  }

  /**
   * Trackso site keys the user may see, or null for "all" (admins).
   * Maps each accessible plant's name to its Trackso site key.
   */
  async getAccessibleSiteKeys(user: AccessUser): Promise<string[] | null> {
    if (user.role === Role.ADMIN) return null;
    const ids = await this.getAccessiblePlantIds(user);
    if (ids.length === 0) return [];
    const plants = await this.prisma.plant.findMany({
      where: { id: { in: ids } },
      select: { name: true },
    });
    const keys = new Set<string>();
    for (const p of plants) {
      const key = siteKeyForPlantName(p.name);
      if (key) keys.add(key);
    }
    return [...keys];
  }

  async canAccessPlant(user: AccessUser, plantId: string): Promise<boolean> {
    if (user.role === Role.ADMIN) return true;
    const owns = await this.prisma.plant.findFirst({
      where: { id: plantId, ownerId: user.id },
      select: { id: true },
    });
    if (owns) return true;
    const grant = await this.prisma.plantAccess.findUnique({
      where: { userId_plantId: { userId: user.id, plantId } },
      select: { id: true },
    });
    return !!grant;
  }

  /** Throws 403 unless the user may access the plant. */
  async assertPlantAccess(user: AccessUser, plantId: string): Promise<void> {
    const ok = await this.canAccessPlant(user, plantId);
    if (!ok) {
      throw new ForbiddenException('You do not have access to this plant');
    }
  }

  // ── Admin management ──────────────────────────────────────────────────────

  /** Replace a user's granted plants with the given set (owner plants untouched). */
  async setUserPlants(userId: string, plantIds: string[]): Promise<void> {
    await this.prisma.$transaction([
      this.prisma.plantAccess.deleteMany({ where: { userId } }),
      ...plantIds.map((plantId) =>
        this.prisma.plantAccess.create({ data: { userId, plantId } }),
      ),
    ]);
  }

  async assignPlant(userId: string, plantId: string): Promise<void> {
    await this.prisma.plantAccess.upsert({
      where: { userId_plantId: { userId, plantId } },
      update: {},
      create: { userId, plantId },
    });
  }

  async revokePlant(userId: string, plantId: string): Promise<void> {
    await this.prisma.plantAccess.deleteMany({ where: { userId, plantId } });
  }

  /** Plants a user can access (owned + granted), with an `owned` flag. */
  async getUserPlants(userId: string) {
    const [owned, grants] = await Promise.all([
      this.prisma.plant.findMany({ where: { ownerId: userId } }),
      this.prisma.plantAccess.findMany({
        where: { userId },
        include: { plant: true },
      }),
    ]);
    const result = owned.map((p) => ({ ...p, owned: true }));
    for (const g of grants) {
      if (!result.find((p) => p.id === g.plantId)) {
        result.push({ ...g.plant, owned: false });
      }
    }
    return result;
  }

  /** Users who can access a plant (owner + granted). */
  async getPlantUsers(plantId: string) {
    const plant = await this.prisma.plant.findUnique({
      where: { id: plantId },
      include: { owner: true, accessGrants: { include: { user: true } } },
    });
    if (!plant) return [];
    const users = [{ ...plant.owner, owned: true }];
    for (const g of plant.accessGrants) {
      if (!users.find((u) => u.id === g.userId)) {
        users.push({ ...g.user, owned: false });
      }
    }
    return users.map((u) => ({
      id: u.id,
      name: u.name,
      email: u.email,
      role: u.role,
      owned: u.owned,
    }));
  }
}
