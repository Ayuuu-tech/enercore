import { UsersService } from '../application/users.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { UserEntity } from '../domain/user.entity';
export declare class UsersController {
    private readonly usersService;
    constructor(usersService: UsersService);
    getProfile(user: UserEntity): Promise<UserEntity>;
    findAll(): Promise<UserEntity[]>;
    findOne(id: string, currentUser: UserEntity): Promise<UserEntity>;
    update(id: string, updateUserDto: UpdateUserDto, currentUser: UserEntity): Promise<UserEntity>;
    uploadAvatar(id: string, file: any, currentUser: UserEntity): Promise<UserEntity>;
    remove(id: string): Promise<boolean>;
}
