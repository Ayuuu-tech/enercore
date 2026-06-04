import { PanelStatus } from '@prisma/client';

export class PanelEntity {
  id: string;
  row: number;
  column: number;
  status: PanelStatus;
  voltage: number;
  current: number;
  temperature: number;
  generation: number;
  lastSync: Date;
  plantId: string;

  constructor(partial: Partial<PanelEntity>) {
    Object.assign(this, partial);
  }
}
