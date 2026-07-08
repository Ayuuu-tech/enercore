import { SubscriptionPlan, SubscriptionStatus } from '@prisma/client';
import { addPeriod, effectiveStatus } from './subscription.util';

describe('subscription util', () => {
  describe('effectiveStatus', () => {
    const now = new Date('2026-07-07T00:00:00Z');

    it('flips an ACTIVE-but-expired subscription to EXPIRED', () => {
      const expiry = new Date('2026-07-01T00:00:00Z');
      expect(effectiveStatus(SubscriptionStatus.ACTIVE, expiry, now)).toBe(
        SubscriptionStatus.EXPIRED,
      );
    });

    it('keeps an ACTIVE subscription active before expiry', () => {
      const expiry = new Date('2026-08-01T00:00:00Z');
      expect(effectiveStatus(SubscriptionStatus.ACTIVE, expiry, now)).toBe(
        SubscriptionStatus.ACTIVE,
      );
    });

    it('never overrides a non-active status', () => {
      const expiry = new Date('2026-01-01T00:00:00Z');
      expect(effectiveStatus(SubscriptionStatus.SUSPENDED, expiry, now)).toBe(
        SubscriptionStatus.SUSPENDED,
      );
      expect(effectiveStatus(SubscriptionStatus.PENDING, expiry, now)).toBe(
        SubscriptionStatus.PENDING,
      );
    });
  });

  describe('addPeriod', () => {
    it('adds one month for a monthly plan', () => {
      const start = new Date('2026-07-07T00:00:00Z');
      expect(addPeriod(start, SubscriptionPlan.MONTHLY).getUTCMonth()).toBe(7); // Aug (0-indexed)
    });

    it('adds twelve months for a yearly plan', () => {
      const start = new Date('2026-07-07T00:00:00Z');
      const next = addPeriod(start, SubscriptionPlan.YEARLY);
      expect(next.getUTCFullYear()).toBe(2027);
      expect(next.getUTCMonth()).toBe(6); // Jul
    });

    it('does not mutate the input date', () => {
      const start = new Date('2026-07-07T00:00:00Z');
      addPeriod(start, SubscriptionPlan.YEARLY);
      expect(start.getUTCFullYear()).toBe(2026);
    });
  });
});
