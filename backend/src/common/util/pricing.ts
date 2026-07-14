/**
 * Marketplace pricing. Kept in one place because the app must display exactly
 * what the backend charges — if these ever disagree, a customer is quoted one
 * price and billed another.
 *
 * The vendor keeps their listed price in full. Enercore's commission is added
 * on top, and GST is charged on the total consideration for the goods
 * (list price + commission), which is what the customer actually pays for them.
 *
 * The Dart side mirrors this exactly: lib/features/marketplace/domain/pricing.dart
 */

/** Enercore's commission on a vendor's listed price. */
export const PLATFORM_FEE_RATE = 0.005; // 0.5%

/** GST on the goods. */
export const GST_RATE = 0.18; // 18%

export interface PriceBreakdown {
  /** What the vendor listed, and what the vendor is paid. */
  subtotal: number;
  /** Enercore's commission. */
  platformFee: number;
  /** subtotal + platformFee — the value GST is charged on. */
  taxable: number;
  gst: number;
  /** What the customer pays. */
  total: number;
}

const round2 = (n: number) => Math.round(n * 100) / 100;

/** Breaks a vendor-listed amount down into what the customer pays. */
export function priceBreakdown(subtotal: number): PriceBreakdown {
  const base = round2(subtotal);
  const platformFee = round2(base * PLATFORM_FEE_RATE);
  const taxable = round2(base + platformFee);
  const gst = round2(taxable * GST_RATE);
  return {
    subtotal: base,
    platformFee,
    taxable,
    gst,
    total: round2(taxable + gst),
  };
}

/**
 * The unit price a customer is charged (ex-GST) for a vendor's listed price.
 * The commission is folded in and never itemised.
 */
export function customerUnitPrice(vendorPrice: number): number {
  return round2(vendorPrice * (1 + PLATFORM_FEE_RATE));
}
