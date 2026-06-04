export class TelemetryEntity {
  id: string;
  voltage: number;
  current: number;
  temperature: number;
  generation: number;
  timestamp: Date;
  panelId: string;
  plantId: string;

  constructor(partial: Partial<TelemetryEntity>) {
    Object.assign(this, partial);
  }
}
