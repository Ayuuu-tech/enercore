export class TelemetryEntity {
  id: string;
  voltage: number;
  current: number;
  temperature: number;
  generation: number;
  timestamp: Date;
  /** Null for inverter/plant-level providers (e.g. IO.Next). */
  panelId: string | null;
  plantId: string;

  constructor(partial: Partial<TelemetryEntity>) {
    Object.assign(this, partial);
  }
}
