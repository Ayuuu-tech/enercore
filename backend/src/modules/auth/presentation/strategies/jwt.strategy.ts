import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { AuthService } from '../../application/auth.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private readonly configService: ConfigService,
    private readonly authService: AuthService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET') || 'enercore-super-secret-jwt-key-2026',
    });
  }

  async validate(payload: { sub: string; email: string; role: string }) {
    const user = await this.authService.validateUserById(payload.sub);
    if (!user) {
      throw new UnauthorizedException('User not found or invalid token');
    }
    // Disabled accounts are rejected even if they hold a valid token.
    if (!user.isActive) {
      throw new UnauthorizedException('Your account has been disabled');
    }
    // Return user to be attached to request.user
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      phone: user.phone ?? null,
      company: user.company ?? null,
      gstNumber: user.gstNumber ?? null,
      postalCode: user.postalCode ?? null,
      address: user.address ?? null,
      avatarUrl: user.avatarUrl ?? null,
      createdAt: user.createdAt,
    };
  }
}
