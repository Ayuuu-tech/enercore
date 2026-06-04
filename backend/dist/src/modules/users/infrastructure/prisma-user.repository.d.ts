import { PrismaService } from '../../../common/prisma/prisma.service';
import { UserEntity } from '../domain/user.entity';
import { IUserRepository } from '../domain/user.repository.interface';
export declare class PrismaUserRepository implements IUserRepository {
    private prisma;
    constructor(prisma: PrismaService);
    private mapToEntity;
    findById(id: string): Promise<UserEntity | null>;
    findByEmail(email: string): Promise<UserEntity | null>;
    create(user: Partial<UserEntity>): Promise<UserEntity>;
    update(id: string, user: Partial<UserEntity>): Promise<UserEntity>;
    delete(id: string): Promise<boolean>;
    findAll(): Promise<UserEntity[]>;
}
