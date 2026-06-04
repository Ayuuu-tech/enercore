export class VendorEntity {
  id: string;
  companyName: string;
  rating: number;
  isVerified: boolean;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial: Partial<VendorEntity>) {
    Object.assign(this, partial);
  }
}
