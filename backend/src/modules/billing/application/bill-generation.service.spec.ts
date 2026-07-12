import { BillGenerationService } from './bill-generation.service';
import { PrismaService } from '../../../common/prisma/prisma.service';

/**
 * The billing maths is the part of this system that moves money, so it is
 * covered against the failure modes that actually bit us: an outage in our own
 * sync silently under-billing, a re-run double-billing, and a meter breakdown
 * that contradicts the total it is supposed to break down.
 */
describe('BillGenerationService', () => {
  const PLANT = {
    id: 'p1',
    name: 'Hollister',
    tariff: 4,
    ownerId: 'u1',
  };

  /** Minimal Prisma stand-in; each test supplies the rows it cares about. */
  function makePrisma(opts: {
    daily?: { day: string; energyKwh: number; lifetimeMwh: number }[];
    priorDaily?: { lifetimeMwh: number } | null;
    device?: { deviceName: string; day: string; energyKwh: number; lifetimeKwh: number }[];
    priorDevice?: Record<string, { lifetimeKwh: number } | null>;
    existingInvoice?: { invoiceNumber: string } | null;
  }) {
    const created: any[] = [];
    const prisma = {
      created,
      plant: { findMany: jest.fn().mockResolvedValue([PLANT]) },
      invoice: {
        findFirst: jest.fn().mockResolvedValue(opts.existingInvoice ?? null),
        findMany: jest.fn().mockResolvedValue([]), // invoice-number series starts empty
        create: jest.fn(async ({ data }: any) => {
          created.push(data);
          return { ...data, id: 'inv1' };
        }),
      },
      dailyEnergy: {
        findMany: jest.fn().mockResolvedValue(opts.daily ?? []),
        findFirst: jest.fn().mockResolvedValue(opts.priorDaily ?? null),
      },
      deviceDailyEnergy: {
        findMany: jest.fn().mockResolvedValue(opts.device ?? []),
        findFirst: jest.fn(async ({ where }: any) =>
          (opts.priorDevice ?? {})[where.deviceName] ?? null,
        ),
      },
    };
    return prisma as unknown as PrismaService & { created: any[] };
  }

  const service = (prisma: PrismaService) => new BillGenerationService(prisma);

  it('bills the meter counter delta, not the sum of daily readings', async () => {
    // Our sync was down for most of July: only two days were recorded. The
    // plant's cumulative counter kept running through the outage, so the bill
    // must reflect the whole month (5000 kWh), not the 300 kWh we happened to
    // observe. Summing dailies here would under-bill by 94%.
    const prisma = makePrisma({
      priorDaily: { lifetimeMwh: 100 }, // 100 MWh at the end of June
      daily: [
        { day: '2026-07-30', energyKwh: 150, lifetimeMwh: 104.85 },
        { day: '2026-07-31', energyKwh: 150, lifetimeMwh: 105 }, // 105 MWh at month end
      ],
    });
    const [bill] = await service(prisma).generateForMonth('2026-07');

    expect(bill.units).toBe(5000); // (105 − 100) MWh → kWh
    expect(bill.amount).toBe(20000); // 5000 × ₹4
    expect(bill.units).not.toBe(300); // the naive sum-of-dailies answer
  });

  it('opens the counter from the first recorded day when there is no prior month', async () => {
    // First month we ever saw this plant: back the first day's own generation
    // out of its counter to get the opening reading.
    const prisma = makePrisma({
      priorDaily: null,
      daily: [
        { day: '2026-07-01', energyKwh: 100, lifetimeMwh: 10.1 }, // opened at 10,000 kWh
        { day: '2026-07-31', energyKwh: 100, lifetimeMwh: 11 },
      ],
    });
    const [bill] = await service(prisma).generateForMonth('2026-07');

    expect(bill.units).toBe(1000); // 11,000 − 10,000
  });

  it('never double-bills a plant for a period', async () => {
    const prisma = makePrisma({ existingInvoice: { invoiceNumber: 'ENERCORE/007' } });
    const [bill] = await service(prisma).generateForMonth('2026-07');

    expect(bill.skipped).toContain('already billed');
    expect((prisma as any).invoice.create).not.toHaveBeenCalled();
  });

  it('skips a plant with no readings rather than billing it zero', async () => {
    const prisma = makePrisma({ daily: [] });
    const [bill] = await service(prisma).generateForMonth('2026-07');

    expect(bill.skipped).toContain('no energy data');
    expect((prisma as any).invoice.create).not.toHaveBeenCalled();
  });

  it('prints the meter breakdown when it reconciles with the plant counter', async () => {
    // Two inverters, 600 + 400 kWh, against a plant counter that also says 1000.
    const prisma = makePrisma({
      priorDaily: { lifetimeMwh: 10 },
      daily: [{ day: '2026-07-31', energyKwh: 50, lifetimeMwh: 11 }], // 1000 kWh
      priorDevice: { 'Inv 1': { lifetimeKwh: 5000 }, 'Inv 2': { lifetimeKwh: 3000 } },
      device: [
        { deviceName: 'Inv 1', day: '2026-07-31', energyKwh: 20, lifetimeKwh: 5600 },
        { deviceName: 'Inv 2', day: '2026-07-31', energyKwh: 30, lifetimeKwh: 3400 },
      ],
    });
    const p = prisma as any;
    await service(prisma).generateForMonth('2026-07');

    const meters = p.created[0].meterReadings.create;
    expect(meters).toHaveLength(2);
    expect(meters.map((m: any) => m.totalUnits)).toEqual([600, 400]);
    // The table must add up to the billed total — it is a breakdown of it.
    expect(meters.reduce((s: number, m: any) => s + m.totalUnits, 0)).toBe(p.created[0].units);
  });

  it('omits a meter breakdown that contradicts the total, and still bills the full total', async () => {
    // One inverter stopped reporting, so the meters only account for 600 of the
    // 1000 kWh the plant counter recorded. Trusting the meters would under-bill;
    // printing them would contradict the total. Do neither.
    const prisma = makePrisma({
      priorDaily: { lifetimeMwh: 10 },
      daily: [{ day: '2026-07-31', energyKwh: 50, lifetimeMwh: 11 }], // 1000 kWh
      priorDevice: { 'Inv 1': { lifetimeKwh: 5000 } },
      device: [{ deviceName: 'Inv 1', day: '2026-07-31', energyKwh: 20, lifetimeKwh: 5600 }],
    });
    const p = prisma as any;
    const [bill] = await service(prisma).generateForMonth('2026-07');

    expect(bill.units).toBe(1000); // full counter total, not the 600 the meters saw
    expect(p.created[0].meterReadings).toBeUndefined(); // breakdown withheld
  });
});
