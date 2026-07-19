import * as Sentry from '@sentry/node';
import { Logger } from '@nestjs/common';

let enabled = false;

/**
 * Initialise error monitoring, if configured. Called once at bootstrap, before
 * the app is created so Sentry can instrument early.
 *
 * It is deliberately opt-in: with no SENTRY_DSN set (local dev, or before an
 * account is wired up) this is a no-op and the app behaves exactly as before.
 * When set, unhandled server errors are reported with request context so a
 * production crash raises an alert instead of sitting unread in the log stream.
 */
export function initSentry(): void {
  const dsn = process.env.SENTRY_DSN;
  if (!dsn) return;

  Sentry.init({
    dsn,
    environment: process.env.NODE_ENV ?? 'development',
    // Sample a slice of traces for performance visibility without flooding the
    // free tier; errors are always captured regardless of this rate.
    tracesSampleRate: 0.1,
  });
  enabled = true;
  new Logger('Sentry').log('Error monitoring enabled');
}

export function isSentryEnabled(): boolean {
  return enabled;
}

/** Report an exception, with optional request context, when Sentry is on. */
export function captureException(
  error: unknown,
  context?: { method?: string; url?: string },
): void {
  if (!enabled) return;
  Sentry.captureException(error, context ? { extra: context } : undefined);
}
