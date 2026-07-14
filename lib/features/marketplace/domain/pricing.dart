/// Marketplace pricing.
///
/// This must stay identical to the backend's `common/util/pricing.ts` — the app
/// shows the customer a price, and the backend charges them. If the two ever
/// disagree, someone is quoted one number and billed another.
///
/// The vendor keeps their listed price in full. Enercore's commission is added
/// on top, and GST is charged on the total consideration for the goods
/// (list price + commission), which is what the customer actually pays for them.
library;

/// Enercore's commission on a vendor's listed price.
const double kPlatformFeeRate = 0.005; // 0.5%

/// GST on the goods.
const double kGstRate = 0.18; // 18%

class PriceBreakdown {
  /// What the vendor listed, and what the vendor is paid.
  final double subtotal;

  /// Enercore's commission.
  final double platformFee;

  /// subtotal + platformFee — the value GST is charged on.
  final double taxable;

  final double gst;

  /// What the customer pays.
  final double total;

  const PriceBreakdown({
    required this.subtotal,
    required this.platformFee,
    required this.taxable,
    required this.gst,
    required this.total,
  });
}

double _round2(num n) => (n * 100).round() / 100;

/// Breaks a vendor-listed amount down into what the customer pays.
PriceBreakdown priceBreakdown(num subtotal) {
  final base = _round2(subtotal);
  final platformFee = _round2(base * kPlatformFeeRate);
  final taxable = _round2(base + platformFee);
  final gst = _round2(taxable * kGstRate);
  return PriceBreakdown(
    subtotal: base,
    platformFee: platformFee,
    taxable: taxable,
    gst: gst,
    total: _round2(taxable + gst),
  );
}

/// The all-inclusive price a customer sees for a single unit.
double displayPrice(num vendorPrice) => priceBreakdown(vendorPrice).total;
