import { AuthService } from '../application/auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UserEntity } from '../../../modules/users/domain/user.entity';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    register(registerDto: RegisterDto): Promise<{
        user: {
            id: string;
            email: string;
            name: string;
            role: import("@prisma/client").$Enums.Role;
        };
        accessToken: string;
    }>;
    login(loginDto: LoginDto): Promise<{
        user: {
            id: string;
            email: string;
            name: string;
            role: import("@prisma/client").$Enums.Role;
            phone: string | null;
            company: string | null;
            gstNumber: string | null;
            postalCode: string | null;
            address: string | null;
            avatarUrl: string | null;
            vendorProfile: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                companyName: string;
                rating: number;
                isVerified: boolean;
            } | null;
        };
        accessToken: string;
    }>;
    changePassword(user: UserEntity, dto: ChangePasswordDto): Promise<{
        message: string;
    }>;
}
