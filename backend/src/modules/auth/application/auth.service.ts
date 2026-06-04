import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { RegisterDto } from '../presentation/dto/register.dto';
import { LoginDto } from '../presentation/dto/login.dto';
import { ChangePasswordDto } from '../presentation/dto/change-password.dto';
import { Role } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    // Check if user exists
    const existing = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    if (dto.role === Role.VENDOR && !dto.companyName) {
      throw new BadRequestException('Company name is required for vendor registration');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(dto.password, 10);

    // Create user in transaction
    const user = await this.prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: {
          email: dto.email,
          password: hashedPassword,
          name: dto.name,
          role: dto.role,
        },
      });

      if (dto.role === Role.VENDOR) {
        await tx.vendor.create({
          data: {
            id: newUser.id,
            companyName: dto.companyName!,
          },
        });
      }

      return newUser;
    });

    const payload = { sub: user.id, email: user.email, role: user.role };
    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
      accessToken: this.jwtService.sign(payload),
    };
  }

  async login(dto: LoginDto) {
    console.log(`[AuthService] Login attempt for email: "${dto.email}"`);
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
      include: { vendorProfile: true },
    });

    if (!user) {
      console.warn(`[AuthService] Login failed: User with email "${dto.email}" not found.`);
      throw new UnauthorizedException('Invalid credentials');
    }

    const passwordMatch = await bcrypt.compare(dto.password, user.password);
    if (!passwordMatch) {
      console.warn(`[AuthService] Login failed: Password mismatch for email "${dto.email}". (Supplied: "${dto.password}")`);
      throw new UnauthorizedException('Invalid credentials');
    }

    console.log(`[AuthService] Login successful for email: "${dto.email}"`);
    const payload = { sub: user.id, email: user.email, role: user.role };
    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        phone: user.phone,
        company: user.company,
        gstNumber: user.gstNumber,
        postalCode: user.postalCode,
        address: user.address,
        avatarUrl: user.avatarUrl,
        vendorProfile: user.vendorProfile,
      },
      accessToken: this.jwtService.sign(payload),
    };
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const passwordMatch = await bcrypt.compare(dto.oldPassword, user.password);
    if (!passwordMatch) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    const hashedPassword = await bcrypt.hash(dto.newPassword, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword },
    });

    return { message: 'Password changed successfully' };
  }

  async validateUserById(id: string) {
    return this.prisma.user.findUnique({ where: { id } });
  }
}
