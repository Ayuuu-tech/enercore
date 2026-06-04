export class ProductEntity {
  id: string;
  title: string;
  brand: string;
  spec: string;
  rating: number;
  reviewsCount: number;
  price: number;
  originalPrice?: number | null;
  isAssured: boolean;
  category: string;
  stock: number;
  vendorId: string;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial: Partial<ProductEntity>) {
    Object.assign(this, partial);
  }
}
