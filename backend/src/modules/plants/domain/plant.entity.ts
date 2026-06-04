export class PlantEntity {
  id: string;
  name: string;
  location: string;
  peakCapacity: number;
  status: string;
  ownerId: string;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial: Partial<PlantEntity>) {
    Object.assign(this, partial);
  }
}
