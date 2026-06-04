import { IUserRepository } from '../domain/user.repository.interface';
import { UserEntity } from '../domain/user.entity';
export declare class UsersService {
    private readonly userRepository;
    constructor(userRepository: IUserRepository);
    findById(id: string): Promise<UserEntity>;
    findByEmail(email: string): Promise<UserEntity | null>;
    create(user: Partial<UserEntity>): Promise<UserEntity>;
    update(id: string, userDto: Partial<UserEntity>): Promise<UserEntity>;
    remove(id: string): Promise<boolean>;
    findAll(): Promise<UserEntity[]>;
}
