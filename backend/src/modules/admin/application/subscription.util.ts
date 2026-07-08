import { SubscriptionPlan, SubscriptionStatus } from '@prisma/client';

/**
 * Effective status of a subscription. An ACTIVE subscription whose expiry has
 * passed reads as EXPIRED without needing a background job to flip it.
 */
export function effectiveStatus(
  status: SubscriptionStatus,
  expiry: Date,
  now: Date = new Date(),
): SubscriptionStatus {
  if (status === SubscriptionStatus.ACTIVE && expiry.getTime() < now.getTime()) {
    return SubscriptionStatus.EXPIRED;
  }
  return status;
}

/** Adds one plan period (1 month / 12 months) to a date. */
export function addPeriod(from: Date, plan: SubscriptionPlan): Date {
  const d = new Date(from);
  d.setMonth(d.getMonth() + (plan === SubscriptionPlan.YEARLY ? 12 : 1));
  return d;
}
