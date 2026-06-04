import { Role } from '@prisma/client';

export class UserEntity {
  id: string;
  email: string;
  password?: string;
  name: string;
  role: Role;
  phone?: string | null;
  company?: string | null;
  gstNumber?: string | null;
  postalCode?: string | null;
  address?: string | null;
  avatarUrl?: string | null;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial: Partial<UserEntity>) {
    Object.assign(this, partial);
  }
}
