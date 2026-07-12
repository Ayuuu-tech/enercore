import { istDay, istMonth, istMonthBounds, monthLabel, previousIstMonth } from './ist-day';

// Billing periods are reckoned in IST. UTC-based date maths would put late-
// evening IST readings on the wrong day — and, at month ends, the wrong bill.
describe('IST date helpers', () => {
  const at = (iso: string) => new Date(iso).getTime();

  describe('istDay', () => {
    it('keeps a mid-day UTC instant on the same IST day', () => {
      expect(istDay(at('2026-07-12T06:00:00Z'))).toBe('2026-07-12');
    });

    it('rolls to the next IST day after 18:30 UTC', () => {
      // 18:29 UTC = 23:59 IST (same day); 18:30 UTC = 00:00 IST (next day).
      expect(istDay(at('2026-07-12T18:29:00Z'))).toBe('2026-07-12');
      expect(istDay(at('2026-07-12T18:30:00Z'))).toBe('2026-07-13');
    });

    it('rolls the month over at the IST boundary, not the UTC one', () => {
      expect(istDay(at('2026-07-31T18:30:00Z'))).toBe('2026-08-01');
    });
  });

  describe('istMonth', () => {
    it('reports the IST month', () => {
      expect(istMonth(at('2026-07-31T18:30:00Z'))).toBe('2026-08');
    });
  });

  describe('previousIstMonth', () => {
    it('returns the month just ended', () => {
      expect(previousIstMonth(at('2026-08-01T00:00:00Z'))).toBe('2026-07');
    });

    it('wraps across the new year', () => {
      expect(previousIstMonth(at('2026-01-01T06:00:00Z'))).toBe('2025-12');
    });
  });

  describe('istMonthBounds', () => {
    it('spans the whole IST month', () => {
      const { start, end, days } = istMonthBounds('2026-07');
      expect(days).toBe(31);
      // 1 Jul 00:00 IST = 30 Jun 18:30 UTC
      expect(start.toISOString()).toBe('2026-06-30T18:30:00.000Z');
      // ends one second before 1 Aug 00:00 IST
      expect(end.toISOString()).toBe('2026-07-31T18:29:59.000Z');
    });

    it('knows February in a leap year', () => {
      expect(istMonthBounds('2024-02').days).toBe(29);
      expect(istMonthBounds('2026-02').days).toBe(28);
    });

    it('gives the day count the bill prints', () => {
      expect(istMonthBounds('2026-05').days).toBe(31);
      expect(istMonthBounds('2026-06').days).toBe(30);
    });
  });

  describe('monthLabel', () => {
    it('formats the period as printed on the bill', () => {
      expect(monthLabel('2026-05')).toBe('May 2026');
      expect(monthLabel('2026-01')).toBe('January 2026');
    });
  });
});
