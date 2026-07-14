import { priceBreakdown, PLATFORM_FEE_RATE, GST_RATE } from './pricing';

/**
 * The app quotes a price and the backend charges it. These numbers are pinned
 * because a mismatch means a customer is shown one amount and billed another —
 * and the same cases are pinned on the Dart side (test/pricing_test.dart).
 */
describe('marketplace pricing', () => {
  it('adds the platform fee, then charges GST on the marked-up value', () => {
    const p = priceBreakdown(10000);

    expect(p.subtotal).toBe(10000); // the vendor is paid in full
    expect(p.platformFee).toBe(50); // 0.5%
    expect(p.taxable).toBe(10050); // GST is charged on this
    expect(p.gst).toBe(1809); // 18% of 10050, not of 10000
    expect(p.total).toBe(11859);
  });

  it('prices a real product (Rs 82,000 inverter)', () => {
    const p = priceBreakdown(82000);

    expect(p.platformFee).toBe(410);
    expect(p.gst).toBe(14833.8);
    expect(p.total).toBe(97243.8);
  });

  it('rounds every component to paise', () => {
    const p = priceBreakdown(18450);

    expect(p.platformFee).toBe(92.25);
    expect(p.taxable).toBe(18542.25);
    expect(p.gst).toBe(3337.61); // 3337.605 -> 3337.61
    expect(p.total).toBe(21879.86);
  });

  it('holds the identity subtotal + fee + gst = total', () => {
    for (const amount of [1, 999, 15200, 82000, 1234567]) {
      const p = priceBreakdown(amount);
      const sum = Math.round((p.subtotal + p.platformFee + p.gst) * 100) / 100;
      expect(sum).toBeCloseTo(p.total, 2);
    }
  });

  it('is zero all the way down for an empty cart', () => {
    const p = priceBreakdown(0);
    expect(p.total).toBe(0);
    expect(p.gst).toBe(0);
  });

  it('uses the agreed rates', () => {
    expect(PLATFORM_FEE_RATE).toBe(0.005);
    expect(GST_RATE).toBe(0.18);
  });
});
