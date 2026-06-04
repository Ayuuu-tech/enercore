import { Role } from '@prisma/client';
export declare class UpdateUserDto {
    email?: string;
    password?: string;
    name?: string;
    role?: Role;
    phone?: string;
    company?: string;
    gstNumber?: string;
    postalCode?: string;
    address?: string;
    avatarUrl?: string;
}
