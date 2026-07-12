/** All billing/energy periods are reckoned on the India calendar. */
export const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

/** Calendar day in IST as "YYYY-MM-DD". Sorts chronologically as a string. */
export function istDay(ms: number): string {
  return new Date(ms + IST_OFFSET_MS).toISOString().slice(0, 10);
}

/** Calendar month in IST as "YYYY-MM". */
export function istMonth(ms: number): string {
  return istDay(ms).slice(0, 7);
}

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/** "2026-05" → "May 2026" (the human period printed on the bill). */
export function monthLabel(month: string): string {
  const [y, m] = month.split('-');
  return `${MONTHS[parseInt(m, 10) - 1]} ${y}`;
}

/** The IST month preceding the given instant, as "YYYY-MM". */
export function previousIstMonth(ms: number): string {
  const ist = new Date(ms + IST_OFFSET_MS);
  const y = ist.getUTCFullYear();
  const m = ist.getUTCMonth(); // 0-based
  const prev = new Date(Date.UTC(y, m - 1, 1));
  return `${prev.getUTCFullYear()}-${String(prev.getUTCMonth() + 1).padStart(2, '0')}`;
}

/** UTC instants bounding an IST calendar month "YYYY-MM". */
export function istMonthBounds(month: string): { start: Date; end: Date; days: number } {
  const [y, m] = month.split('-').map(Number);
  const start = new Date(Date.UTC(y, m - 1, 1) - IST_OFFSET_MS);
  const end = new Date(Date.UTC(y, m, 1) - IST_OFFSET_MS - 1000);
  const days = new Date(Date.UTC(y, m, 0)).getUTCDate();
  return { start, end, days };
}
