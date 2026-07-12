import { ForbiddenException } from '@nestjs/common';
import { Role } from '@prisma/client';
import { PlantAccessService } from './plant-access.service';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Plant access is enforced here, not in the UI — a client must never be able to
 * read another client's plant by calling the API directly. These tests pin that
 * behaviour, and the dashboard-key scoping that keeps one tenant's telemetry out
 * of another's dashboard.
 */
describe('PlantAccessService', () => {
  const CLIENT = { id: 'u1', role: Role.CLIENT };
  const ADMIN = { id: 'admin', role: Role.ADMIN };

  function makePrisma(opts: {
    owned?: any[];
    granted?: { plantId: string }[];
    all?: any[];
    grant?: { id: string } | null;
  }) {
    return {
      plant: {
        findMany: jest.fn(async ({ where }: any) =>
          where?.ownerId ? (opts.owned ?? []) : (opts.all ?? opts.owned ?? []),
        ),
        findFirst: jest.fn(async ({ where }: any) =>
          (opts.owned ?? []).find((p) => p.id === where.id && where.ownerId === 'u1') ?? null,
        ),
      },
      plantAccess: {
        findMany: jest.fn().mockResolvedValue(opts.granted ?? []),
        findUnique: jest.fn().mockResolvedValue(opts.grant ?? null),
      },
    } as unknown as PrismaService;
  }

  describe('canAccessPlant', () => {
    it('lets an admin reach any plant', async () => {
      const svc = new PlantAccessService(makePrisma({}));
      await expect(svc.canAccessPlant(ADMIN, 'someone-elses-plant')).resolves.toBe(true);
    });

    it('lets a client reach a plant they own', async () => {
      const svc = new PlantAccessService(makePrisma({ owned: [{ id: 'p1' }] }));
      await expect(svc.canAccessPlant(CLIENT, 'p1')).resolves.toBe(true);
    });

    it('lets a client reach a plant explicitly granted to them', async () => {
      const svc = new PlantAccessService(makePrisma({ owned: [], grant: { id: 'g1' } }));
      await expect(svc.canAccessPlant(CLIENT, 'p2')).resolves.toBe(true);
    });

    it("refuses a plant the client neither owns nor was granted", async () => {
      const svc = new PlantAccessService(makePrisma({ owned: [], grant: null }));
      await expect(svc.canAccessPlant(CLIENT, 'p9')).resolves.toBe(false);
    });
  });

  describe('assertPlantAccess', () => {
    it('throws 403 rather than leaking another tenant’s plant', async () => {
      const svc = new PlantAccessService(makePrisma({ owned: [], grant: null }));
      await expect(svc.assertPlantAccess(CLIENT, 'p9')).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('getAccessibleSiteKeys', () => {
    it('returns null for an admin, meaning "every site"', async () => {
      const svc = new PlantAccessService(makePrisma({}));
      await expect(svc.getAccessibleSiteKeys(ADMIN)).resolves.toBeNull();
    });

    it('returns an empty list when a client has no plants (so no data leaks)', async () => {
      const svc = new PlantAccessService(makePrisma({ owned: [], granted: [] }));
      await expect(svc.getAccessibleSiteKeys(CLIENT)).resolves.toEqual([]);
    });

    it('namespaces IO.Next keys so they cannot collide with Trackso site keys', async () => {
      const prisma = makePrisma({ owned: [{ id: 'p1' }, { id: 'p2' }], granted: [] });
      (prisma as any).plant.findMany = jest
        .fn()
        // getAccessiblePlantIds → owned
        .mockResolvedValueOnce([{ id: 'p1' }, { id: 'p2' }])
        // then the key lookup
        .mockResolvedValueOnce([
          { name: 'Hollister', dataSource: 'TRACKSO', externalKey: '38124d4420' },
          { name: 'Hella India', dataSource: 'IONEXT', externalKey: '130' },
        ]);

      const keys = await new PlantAccessService(prisma).getAccessibleSiteKeys(CLIENT);
      expect(keys).toEqual(['38124d4420', 'IN:130']);
    });
  });
});
