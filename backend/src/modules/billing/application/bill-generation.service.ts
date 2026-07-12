import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import {
  IST_OFFSET_MS,
  istDay,
  istMonthBounds,
  monthLabel,
  previousIstMonth,
} from '../../../common/util/ist-day';
import { withJobLock } from '../../../common/util/job-lock';

export interface GeneratedBill {
  plant: string;
  period: string;
  units: number;
  amount: number;
  skipped?: string;
}

/**
 * Creates one solar bill of supply per plant, per calendar month.
 *
 * Runs on the 1st of every month (IST) for the month just ended. Units come
 * from the plant's cumulative generation counter (end reading − start reading),
 * the same way a physical meter bills — so an outage in our own sync never
 * undercounts. Generation is idempotent: `Invoice` is unique on
 * (plantId, period), and the job takes an advisory lock, so neither a re-run
 * nor a second replica can double-bill.
 */
@Injectable()
export class BillGenerationService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(BillGenerationService.name);
  private timer?: NodeJS.Timeout;

  constructor(private readonly prisma: PrismaService) {}

  onModuleInit() {
    // Check hourly rather than scheduling a month ahead: survives restarts,
    // and the (plantId, period) unique constraint makes re-checks harmless.
    this.timer = setInterval(() => {
      this.runIfBillingDay().catch((e) => this.logger.error('Bill generation failed:', e));
    }, 60 * 60 * 1000);
    this.runIfBillingDay().catch((e) => this.logger.error('Bill generation failed:', e));
  }

  onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
  }

  private async runIfBillingDay() {
    const istNow = new Date(Date.now() + IST_OFFSET_MS);
    if (istNow.getUTCDate() !== 1) return;
    const period = previousIstMonth(Date.now());
    // Only one replica generates the month's bills.
    await withJobLock(this.prisma, 'bill-generation', async () => {
      this.logger.log(`Billing day — generating bills for ${period}`);
      await this.generateForMonth(period);
    });
  }

  /** Next invoice number in the ENERCORE/NNN series. */
  private async nextInvoiceNumber(): Promise<string> {
    const last = await this.prisma.invoice.findMany({
      where: { invoiceNumber: { startsWith: 'ENERCORE/' } },
      select: { invoiceNumber: true },
    });
    let max = 0;
    for (const i of last) {
      const n = parseInt(i.invoiceNumber.split('/')[1] ?? '', 10);
      if (Number.isFinite(n) && n > max) max = n;
    }
    return `ENERCORE/${String(max + 1).padStart(3, '0')}`;
  }

  /**
   * Per-device start/end counter readings for the period — the bill's meter
   * table. Each device is read the same way the plant is: the counter as of the
   * last reading before the month, against its last reading within the month.
   */
  private async meterReadings(plantId: string, period: string) {
    const rows = await this.prisma.deviceDailyEnergy.findMany({
      where: { plantId, day: { startsWith: period } },
      orderBy: { day: 'asc' },
      select: { deviceName: true, day: true, energyKwh: true, lifetimeKwh: true },
    });
    if (rows.length === 0) return [];

    const byDevice = new Map<string, typeof rows>();
    for (const r of rows) {
      const list = byDevice.get(r.deviceName) ?? [];
      list.push(r);
      byDevice.set(r.deviceName, list);
    }

    const readings: {
      meterName: string;
      startReading: number;
      endReading: number;
      multiplier: number;
      adjustment: number;
      totalUnits: number;
    }[] = [];

    for (const [deviceName, list] of [...byDevice].sort((a, b) => a[0].localeCompare(b[0]))) {
      const prior = await this.prisma.deviceDailyEnergy.findFirst({
        where: { plantId, deviceName, day: { lt: `${period}-01` } },
        orderBy: { day: 'desc' },
        select: { lifetimeKwh: true },
      });
      const first = list[0];
      const last = list[list.length - 1];
      const startReading = parseFloat(
        (prior ? prior.lifetimeKwh : first.lifetimeKwh - first.energyKwh).toFixed(2),
      );
      const endReading = parseFloat(last.lifetimeKwh.toFixed(2));
      readings.push({
        meterName: deviceName,
        startReading,
        endReading,
        multiplier: 1,
        adjustment: 0,
        totalUnits: parseFloat(Math.max(0, endReading - startReading).toFixed(2)),
      });
    }
    return readings;
  }

  /**
   * Generate bills for every plant for the given IST month ("YYYY-MM").
   * Returns a per-plant result, including why a plant was skipped.
   */
  async generateForMonth(period: string): Promise<GeneratedBill[]> {
    const { start, end, days } = istMonthBounds(period);
    const label = monthLabel(period);
    const plants = await this.prisma.plant.findMany();
    const results: GeneratedBill[] = [];

    for (const plant of plants) {
      const existing = await this.prisma.invoice.findFirst({
        where: { plantId: plant.id, period: label },
        select: { invoiceNumber: true },
      });
      if (existing) {
        results.push({
          plant: plant.name, period: label, units: 0, amount: 0,
          skipped: `already billed (${existing.invoiceNumber})`,
        });
        continue;
      }

      const rows = await this.prisma.dailyEnergy.findMany({
        where: { plantId: plant.id, day: { startsWith: period } },
        orderBy: { day: 'asc' },
        select: { day: true, energyKwh: true, lifetimeMwh: true },
      });
      if (rows.length === 0) {
        results.push({
          plant: plant.name, period: label, units: 0, amount: 0,
          skipped: 'no energy data recorded for this month',
        });
        continue;
      }

      // Bill off the plant's cumulative generation counter, exactly as a real
      // meter does (end reading − start reading). Summing the daily rows would
      // silently undercount any day the sync was down; the counter keeps
      // running regardless, so the delta stays correct across outages.
      const first = rows[0];
      const last = rows[rows.length - 1];
      const endReading = parseFloat((last.lifetimeMwh * 1000).toFixed(2));

      // Preferred start: the counter as of the last reading before this month.
      const prior = await this.prisma.dailyEnergy.findFirst({
        where: { plantId: plant.id, day: { lt: `${period}-01` } },
        orderBy: { day: 'desc' },
        select: { lifetimeMwh: true },
      });
      // Fallback (first month we ever recorded this plant): back out the first
      // day's own generation from its counter to get that day's opening value.
      const startReading = parseFloat(
        (prior
          ? prior.lifetimeMwh * 1000
          : first.lifetimeMwh * 1000 - first.energyKwh
        ).toFixed(2),
      );

      // The plant counter is the authoritative total: it is a single cumulative
      // meter that keeps running through any outage, on our side or a device's.
      const units = parseFloat(Math.max(0, endReading - startReading).toFixed(2));
      const amount = parseFloat((units * plant.tariff).toFixed(2));

      // Per-device readings are a *breakdown* of that total, so they may only be
      // printed when they reconcile with it. They won't if a device stopped
      // reporting, or if we simply have less device history than plant history —
      // printing them then would contradict the total (and under-bill if trusted).
      const allMeters = await this.meterReadings(plant.id, period);
      const meterTotal = parseFloat(allMeters.reduce((s, m) => s + m.totalUnits, 0).toFixed(2));
      const drift = units > 0 ? Math.abs(meterTotal - units) / units : 0;
      const metersReconcile = allMeters.length > 0 && drift <= 0.02;
      const meters = metersReconcile ? allMeters : [];

      if (allMeters.length > 0 && !metersReconcile) {
        this.logger.warn(
          `${plant.name} ${label}: per-meter readings total ${meterTotal} kWh but the ` +
            `plant counter says ${units} kWh (${(drift * 100).toFixed(1)}% apart). ` +
            `Billing the plant counter and omitting the meter breakdown from the bill.`,
        );
      }

      // Flag any day in the period with no reading — the counter delta still
      // bills correctly, but a gap means our own monitoring had an outage.
      const recorded = new Set(rows.map((r) => r.day));
      const missing: string[] = [];
      for (let d = 1; d <= days; d++) {
        const day = `${period}-${String(d).padStart(2, '0')}`;
        if (day <= istDay(Date.now()) && !recorded.has(day)) missing.push(day);
      }
      if (missing.length > 0) {
        this.logger.warn(
          `${plant.name} ${label}: no telemetry recorded on ${missing.length} day(s) ` +
            `(${missing.slice(0, 5).join(', ')}${missing.length > 5 ? ', …' : ''}). ` +
            `Units still billed from the meter counter, so the total is correct.`,
        );
      }

      // Bill dated the 1st of the following month; payment due on the 15th.
      const [y, m] = period.split('-').map(Number);
      const billDate = new Date(Date.UTC(y, m, 1) - IST_OFFSET_MS);
      const dueDate = new Date(Date.UTC(y, m, 15) - IST_OFFSET_MS);

      const invoice = await this.prisma.invoice.create({
        data: {
          invoiceNumber: await this.nextInvoiceNumber(),
          amount,
          units,
          tariff: plant.tariff,
          period: label,
          billDate,
          dueDate,
          periodStart: start,
          periodEnd: end,
          startReading,
          endReading,
          status: 'PENDING',
          userId: plant.ownerId,
          plantId: plant.id,
          // Freeze the readings this bill was raised on — it's a legal document.
          meterReadings: meters.length > 0 ? { create: meters } : undefined,
        },
      });
      this.logger.log(
        `${invoice.invoiceNumber}: ${plant.name} ${label} — ${units} kWh × ₹${plant.tariff} = ₹${amount} (${rows.length}/${days} days)`,
      );
      results.push({ plant: plant.name, period: label, units, amount });
    }
    return results;
  }
}
