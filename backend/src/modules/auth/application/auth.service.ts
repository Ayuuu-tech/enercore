import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  UnauthorizedException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { v4 as uuid } from 'uuid';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { RegisterDto } from '../presentation/dto/register.dto';
import { LoginDto } from '../presentation/dto/login.dto';
import { ChangePasswordDto } from '../presentation/dto/change-password.dto';
import { Role } from '@prisma/client';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

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
          phone: dto.phone,
          // Anyone who signs up themselves is a shop customer: they get the
          // marketplace and nothing else. Clients with plants (dashboards,
          // telemetry, billing) are provisioned by an admin, who widens this.
          ...(dto.role === Role.CLIENT ? { modules: ['marketplace'] } : {}),
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

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        modules: user.modules,
      },
      accessToken: this.signToken(user),
    };
  }

  // Signs an access token carrying the user's current token version. A token
  // is only accepted while its `tv` still matches the user's — bumping the
  // version (password change, log-out-all) invalidates every token at once.
  private signToken(user: { id: string; email: string; role: Role; tokenVersion: number }) {
    return this.jwtService.sign({
      sub: user.id,
      email: user.email,
      role: user.role,
      tv: user.tokenVersion,
    });
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
      include: { vendorProfile: true },
    });

    // Use the same error for missing user / wrong password so we don't leak
    // which emails exist, and don't log credentials or attempted emails.
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const passwordMatch = await bcrypt.compare(dto.password, user.password);
    if (!passwordMatch) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Your account has been disabled. Contact the administrator.');
    }

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        modules: user.modules,
        phone: user.phone,
        company: user.company,
        gstNumber: user.gstNumber,
        postalCode: user.postalCode,
        address: user.address,
        avatarUrl: user.avatarUrl,
        vendorProfile: user.vendorProfile,
      },
      accessToken: this.signToken(user),
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
    // Bumping the version signs out every other session that held a token from
    // the old password. We hand back a fresh token so the caller's own session
    // survives the change instead of being logged out too.
    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword, tokenVersion: { increment: 1 } },
    });

    return {
      message: 'Password changed successfully',
      accessToken: this.signToken(updated),
    };
  }

  /**
   * "Log out of all devices": invalidates every access token this user holds,
   * including the current one, by advancing the token version.
   */
  async logoutAllDevices(userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { tokenVersion: { increment: 1 } },
    });
    return { message: 'Signed out of all devices' };
  }

  private readonly resetTokens = new Map<string, { token: string; expiresAt: Date }>();

  async forgotPassword(email: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      return { message: 'If an account with that email exists, a reset link has been sent.' };
    }

    const token = uuid();
    this.resetTokens.set(token, {
      token,
      expiresAt: new Date(Date.now() + 60 * 60 * 1000), // 1 hour
    });

    // TODO: deliver this token via email. Debug-only so it never lands in
    // production logs at the default level.
    this.logger.debug(`Password reset token generated for a user (dev delivery only).`);

    return { message: 'If an account with that email exists, a reset link has been sent.' };
  }

  async validateUserById(id: string) {
    return this.prisma.user.findUnique({ where: { id } });
  }
}
