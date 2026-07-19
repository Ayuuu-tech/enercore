import { ConfigService } from '@nestjs/config';

/**
 * The single source of truth for the JWT signing secret.
 *
 * There is deliberately no hardcoded fallback: a public default secret would
 * let anyone forge a valid token (including an admin one), so if JWT_SECRET is
 * missing we fail loudly at startup rather than boot with a known key. In
 * non-production we allow a clearly-marked dev secret so a fresh clone runs.
 */
export function resolveJwtSecret(config: ConfigService): string {
  const secret = config.get<string>('JWT_SECRET');
  if (secret && secret.length >= 16) return secret;

  const env = config.get<string>('NODE_ENV');
  if (env === 'production') {
    throw new Error(
      'JWT_SECRET is not set (or is too short). Refusing to start in production ' +
        'with a missing/weak signing key.',
    );
  }
  return 'dev-only-insecure-jwt-secret-not-for-production';
}
