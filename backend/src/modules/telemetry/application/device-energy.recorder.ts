import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { istDay } from '../../../common/util/ist-day';

interface CounterDevice {
  name: string;
  type: string;
  dailyEnergyKwh: number;
  totalEnergyKwh: number;
}

/**
 * Persists each device's cumulative generation counter, once per day.
 * Billing reads these at the period edges to build the bill's meter-readings
 * table — the same start/end reading a physical meter would be read for.
 */
@Injectable()
export class DeviceEnergyRecorder {
  private readonly logger = new Logger(DeviceEnergyRecorder.name);

  constructor(private readonly prisma: PrismaService) {}

  async record(plantId: string, devices: CounterDevice[]): Promise<void> {
    const day = istDay(Date.now());
    // Only generating devices are billed; DG sets and ACDBs are not.
    const billable = devices.filter((d) => d.type === 'INVERTER' && d.totalEnergyKwh > 0);
    for (const d of billable) {
      try {
        await this.prisma.deviceDailyEnergy.upsert({
          where: { plantId_deviceName_day: { plantId, deviceName: d.name, day } },
          update: { energyKwh: d.dailyEnergyKwh, lifetimeKwh: d.totalEnergyKwh },
          create: {
            plantId,
            deviceName: d.name,
            day,
            energyKwh: d.dailyEnergyKwh,
            lifetimeKwh: d.totalEnergyKwh,
          },
        });
      } catch (err) {
        this.logger.error(`Failed to record counter for ${d.name}:`, err);
      }
    }
  }
}
