import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import {
  IST_OFFSET_MS,
  istMonthBounds,
  monthLabel,
  previousIstMonth,
} from '../../../common/util/ist-day';

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
 * Runs on the 1st of every month (IST) for the month just ended. Billed units
 * are the sum of the daily energy snapshots we record for every plant, so the
 * figure is identical regardless of whether the plant reports via Trackso or
 * IO.Next. Generation is idempotent: `Invoice` is unique on (plantId, period),
 * so a re-run never double-bills.
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
    this.logger.log(`Billing day — generating bills for ${period}`);
    await this.generateForMonth(period);
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
        select: { energyKwh: true, lifetimeMwh: true },
      });
      if (rows.length === 0) {
        results.push({
          plant: plant.name, period: label, units: 0, amount: 0,
          skipped: 'no energy data recorded for this month',
        });
        continue;
      }

      const units = parseFloat(rows.reduce((s, r) => s + r.energyKwh, 0).toFixed(2));
      const amount = parseFloat((units * plant.tariff).toFixed(2));
      // Cumulative plant counter at the period edges (kWh), for the readings table.
      const endReading = parseFloat((rows[rows.length - 1].lifetimeMwh * 1000).toFixed(2));
      const startReading = parseFloat((endReading - units).toFixed(2));

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
