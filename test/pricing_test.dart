import 'package:flutter_test/flutter_test.dart';
import 'package:enercore_app/features/marketplace/domain/pricing.dart';

/// These are the *same cases* the backend pins in
/// backend/src/common/util/pricing.spec.ts. If the two ever drift, a customer
/// is quoted one price in the app and charged another by the server.
void main() {
  group('marketplace pricing', () {
    test('adds the platform fee, then charges GST on the marked-up value', () {
      final p = priceBreakdown(10000);

      expect(p.subtotal, 10000); // the vendor is paid in full
      expect(p.platformFee, 50); // 0.5%
      expect(p.taxable, 10050); // GST is charged on this
      expect(p.gst, 1809); // 18% of 10050, not of 10000
      expect(p.total, 11859);
    });

    test('prices a real product (Rs 82,000 inverter)', () {
      final p = priceBreakdown(82000);

      expect(p.platformFee, 410);
      expect(p.gst, 14833.8);
      expect(p.total, 97243.8);
    });

    test('rounds every component to paise', () {
      final p = priceBreakdown(18450);

      expect(p.platformFee, 92.25);
      expect(p.taxable, 18542.25);
      expect(p.gst, 3337.61); // 3337.605 -> 3337.61
      expect(p.total, 21879.86);
    });

    test('holds the identity subtotal + fee + gst = total', () {
      for (final amount in [1, 999, 15200, 82000, 1234567]) {
        final p = priceBreakdown(amount);
        final sum = ((p.subtotal + p.platformFee + p.gst) * 100).round() / 100;
        expect(sum, closeTo(p.total, 0.01), reason: 'at $amount');
      }
    });

    test('is zero all the way down for an empty cart', () {
      final p = priceBreakdown(0);
      expect(p.total, 0);
      expect(p.gst, 0);
    });

    test('displayPrice is the all-in amount the customer pays', () {
      expect(displayPrice(10000), 11859);
    });

    test('uses the agreed rates', () {
      expect(kPlatformFeeRate, 0.005);
      expect(kGstRate, 0.18);
    });
  });
}
