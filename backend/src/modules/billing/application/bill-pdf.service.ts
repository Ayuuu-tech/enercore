import { Injectable, NotFoundException } from '@nestjs/common';
import PDFDocument from 'pdfkit';
import { PrismaService } from '../../../common/prisma/prisma.service';

/** Issuer details — constant across every bill of supply. */
const ISSUER = {
  name: 'Enercore New Energy Private Limited',
  gstin: '09AAICE2947D1ZM',
  office:
    'Registered Office: 20th Floor, Flat No C16-2103, Tower C 16, Prateek Grand City Siddharth Vihar, Ghaziabad, 201009',
  email: 'sales@enercore.org',
  hsn: '27160000',
  bank: { name: 'ICICI BANK', account: 'ESCC00180026', ifsc: 'ICIC0000104' },
  penalty: '2% / Month',
};

const C = {
  text: '#000000',
  muted: '#444444',
  border: '#000000',
  sidebar: '#D9D9D9',
  highlight: '#CFE8F3',
  rowShade: '#EFEFEF',
};

/** Indian digit grouping: 428022.82 → "4,28,022.82" */
function inr(n: number): string {
  const [w, d] = n.toFixed(2).split('.');
  const last3 = w.slice(-3);
  const rest = w.slice(0, -3);
  const grouped = rest ? rest.replace(/\B(?=(\d{2})+(?!\d))/g, ',') + ',' + last3 : last3;
  return `${grouped}.${d}`;
}

function fmtDate(d: Date | null): string {
  if (!d) return '-';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  // Bills are read in IST.
  const ist = new Date(d.getTime() + 5.5 * 60 * 60 * 1000);
  return `${String(ist.getUTCDate()).padStart(2, '0')}-${months[ist.getUTCMonth()]}-${ist.getUTCFullYear()}`;
}

@Injectable()
export class BillPdfService {
  constructor(private readonly prisma: PrismaService) {}

  async generate(invoiceId: string): Promise<{ buffer: Buffer; filename: string }> {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id: invoiceId },
      include: { plant: true },
    });
    if (!invoice) throw new NotFoundException(`Invoice ${invoiceId} not found`);
    if (!invoice.plant) throw new NotFoundException('Invoice has no plant attached');

    const plant = invoice.plant;
    const units = invoice.units ?? 0;
    const tariff = invoice.tariff ?? 0;
    // periodEnd is the last second of the month, so the span already covers
    // every calendar day — rounding it is the day count.
    const days =
      invoice.periodStart && invoice.periodEnd
        ? Math.round(
            (invoice.periodEnd.getTime() - invoice.periodStart.getTime()) / (24 * 3600 * 1000),
          )
        : 0;
    const perDay = days > 0 ? units / days : 0;
    const perKwp = plant.peakCapacity > 0 && days > 0 ? units / plant.peakCapacity / days : 0;

    const doc = new PDFDocument({ size: 'A4', margin: 32 });
    const chunks: Buffer[] = [];
    doc.on('data', (c: Buffer) => chunks.push(c));
    const done = new Promise<Buffer>((resolve) => doc.on('end', () => resolve(Buffer.concat(chunks))));

    this.page1(doc, invoice, plant, { units, tariff, days, perDay, perKwp });
    doc.addPage();
    this.page2(doc, invoice, plant, units);

    doc.end();
    const buffer = await done;
    const safe = invoice.invoiceNumber.replace(/\//g, '-');
    return { buffer, filename: `${safe}-${plant.name.replace(/\s+/g, '-')}.pdf` };
  }

  // ── Page 1: bill summary ──────────────────────────────────────────────────
  private page1(
    doc: PDFKit.PDFDocument,
    inv: any,
    plant: any,
    m: { units: number; tariff: number; days: number; perDay: number; perKwp: number },
  ) {
    const L = 32; // left column x
    const LW = 340; // left column width
    const R = 390; // sidebar x
    const RW = 173; // sidebar width

    doc.fontSize(15).font('Helvetica-Bold').fillColor(C.text).text(ISSUER.name, L, 40, { width: LW });
    doc.moveTo(L, 60).lineTo(L + 250, 60).lineWidth(1).strokeColor(C.text).stroke();

    // Sidebar background runs the height of the summary block.
    doc.rect(R, 36, RW + 10, 560).fill(C.sidebar);

    // ── Bill-to / Ship-to boxes
    let y = 76;
    for (const label of ['Bill To:', 'Ship To:']) {
      const boxTop = y;
      doc.fontSize(9.5).font('Helvetica-Bold').fillColor(C.text);
      let inner = boxTop + 8;
      if (label === 'Bill To:') {
        doc.text(plant.legalName ?? plant.name, L + 8, inner, { width: LW - 16 });
        inner = doc.y + 1;
        doc.fontSize(7.5).font('Helvetica').text(`Offtaker code - ${plant.offtakerCode ?? '-'}`, L + 8, inner, { width: LW - 16 });
        inner = doc.y + 3;
      }
      doc.fontSize(8).font('Helvetica-Bold').text(label, L + 8, inner, { width: LW - 16 });
      inner = doc.y + 1;
      doc.fontSize(7.5).font('Helvetica').text(plant.billingAddress ?? plant.location, L + 8, inner, { width: LW - 16 });
      inner = doc.y + 2;
      doc.fontSize(8).font('Helvetica-Bold').text(`GSTIN: ${plant.gstin ?? '-'}`, L + 8, inner, { width: LW - 16 });
      const boxBottom = doc.y + 8;
      doc.roundedRect(L, boxTop, LW, boxBottom - boxTop, 6).lineWidth(1).strokeColor(C.border).stroke();
      y = boxBottom + 10;
    }

    // ── Capacity
    doc.roundedRect(L, y, LW, 24, 5).lineWidth(1).strokeColor(C.border).stroke();
    doc.fontSize(9).font('Helvetica-Bold').fillColor(C.text)
      .text(`Solar Plant Total Capacity (kW): ${plant.peakCapacity}`, L + 8, y + 8);
    y += 38;

    // ── Summary of consumption
    const sumTop = y;
    doc.fontSize(12).font('Helvetica-Bold').text('SUMMARY OF CONSUMPTION', L + 8, y + 10);
    const cells: [string, string][] = [
      [inr(m.units), 'Total Billed Units'],
      [String(m.days), 'Days'],
      [inr(m.perDay), 'kWh/Day'],
      [m.perKwp.toFixed(2), 'kWh/kWp/Day'],
    ];
    const cw = (LW - 30) / 4;
    cells.forEach(([big, small], i) => {
      const cx = L + 15 + i * cw;
      doc.fontSize(9.5).font('Helvetica-Bold').fillColor('#0B5F8A').text(big, cx, y + 40, { width: cw - 6, align: 'center' });
      doc.fontSize(6.5).font('Helvetica').fillColor(C.muted).text(small, cx, y + 52, { width: cw - 6, align: 'center' });
      if (i > 0) doc.moveTo(cx - 4, y + 38).lineTo(cx - 4, y + 62).lineWidth(0.6).strokeColor('#999999').stroke();
    });
    doc.roundedRect(L, sumTop, LW, 78, 6).lineWidth(1.4).strokeColor(C.border).stroke();
    y = sumTop + 96;

    // ── Breakup of current bill
    doc.fontSize(12).font('Helvetica-Bold').fillColor(C.text).text('BREAKUP OF CURRENT BILL', L, y);
    y += 22;
    // Right-aligned numeric columns, sized so no header wraps.
    const cols = [L, L + 140, L + 218, L + 280];
    const W = [136, 78, 62, 58];
    const cend = L + LW;
    doc.rect(L, y, LW, 16).fill(C.rowShade);
    doc.fontSize(8).font('Helvetica-Bold').fillColor(C.text);
    doc.text('Units(kWh)', cols[1], y + 5, { width: W[1], align: 'right' });
    doc.text('Tariff(Rs/kWh)', cols[2], y + 5, { width: W[2], align: 'right' });
    doc.text('Amount(Rs)', cols[3], y + 5, { width: W[3], align: 'right' });
    y += 16;

    const line = (name: string, u: number, t: number, a: number, bold = false) => {
      doc.fontSize(8.5).font(bold ? 'Helvetica-Bold' : 'Helvetica').fillColor(C.text);
      doc.text(name, cols[0] + 2, y + 6, { width: W[0] });
      doc.text(u.toFixed(2), cols[1], y + 6, { width: W[1], align: 'right' });
      doc.text(t.toFixed(3), cols[2], y + 6, { width: W[2], align: 'right' });
      doc.text(inr(a), cols[3], y + 6, { width: W[3], align: 'right' });
      y += 20;
      doc.moveTo(L, y).lineTo(cend, y).lineWidth(0.4).strokeColor('#CCCCCC').stroke();
    };
    line('Generation', m.units, m.tariff, m.units * m.tariff);
    line('Adjustment(kWh)', 0, m.tariff, 0);
    line('Deemed Generation', 0, m.tariff, 0);

    const totalRow = (name: string, a: number, shade?: string) => {
      if (shade) doc.rect(L, y, LW, 20).fill(shade);
      doc.fontSize(8.5).font('Helvetica-Bold').fillColor(C.text);
      doc.text(name, cols[0] + 2, y + 6, { width: 200 });
      doc.text(inr(a), cols[3], y + 6, { width: W[3], align: 'right' });
      y += 20;
      doc.moveTo(L, y).lineTo(cend, y).lineWidth(0.4).strokeColor('#CCCCCC').stroke();
    };
    totalRow('Solar Charges', inv.amount);
    totalRow('Electricity Duty', 0);
    doc.fontSize(8.5).font('Helvetica-Bold').fillColor(C.text).text('GST @0%', cols[0] + 2, y + 6);
    doc.text('0.00', cols[3], y + 6, { width: W[3], align: 'right' });
    y += 20;
    totalRow('Total Charges', inv.amount, C.highlight);

    y += 12;
    doc.fontSize(7.5).font('Helvetica').fillColor(C.muted).text('Remarks:', L, y);
    doc.roundedRect(L + 45, y - 4, LW - 45, 16, 3).lineWidth(0.6).strokeColor('#BBBBBB').stroke();

    // ── Sidebar
    let sy = 48;
    const kv = (k: string, v: string) => {
      doc.fontSize(8).font('Helvetica-Bold').fillColor(C.text).text(k, R + 6, sy, { width: 74 });
      doc.font('Helvetica').text(v, R + 82, sy, { width: RW - 76 });
      sy = doc.y + 5;
    };
    kv('Bill No:', inv.invoiceNumber);
    kv('Bill Date:', fmtDate(inv.billDate));
    kv('Bill Start Date:', fmtDate(inv.periodStart));
    kv('Bill End Date:', fmtDate(inv.periodEnd));
    kv('HSN Code:', ISSUER.hsn);

    sy += 12;
    doc.fontSize(9.5).font('Helvetica-Bold').text('YOUR BILL OVERVIEW', R + 6, sy);
    sy = doc.y + 6;
    kv('Due Date:', fmtDate(inv.dueDate));
    doc.fontSize(8).font('Helvetica-Bold').text('Late Payment Penalty: ', R + 6, sy, { continued: true })
      .font('Helvetica').text(ISSUER.penalty);
    sy = doc.y + 16;

    doc.fontSize(9).font('Helvetica-Bold').fillColor(C.text).text('Current Invoice Amount', R + 6, sy, { width: RW, align: 'center' });
    sy = doc.y + 6;
    doc.rect(R + 6, sy, RW - 6, 26).fill(C.highlight);
    doc.fontSize(13).font('Helvetica-Bold').fillColor(C.text).text(`Rs ${inr(inv.amount)}`, R + 6, sy + 7, { width: RW - 6, align: 'center' });
    sy += 34;
    doc.fontSize(8).font('Helvetica').text('Equals', R + 6, sy, { width: RW, align: 'center' });
    sy = doc.y + 4;
    doc.rect(R + 6, sy, RW - 6, 15).fill('#FFFFFF');
    doc.fontSize(8).font('Helvetica').fillColor(C.text).text('Current Bill Amount', R + 6, sy + 4, { width: RW - 6, align: 'center' });
    sy += 17;
    doc.rect(R + 6, sy, RW - 6, 15).fill('#FFFFFF');
    doc.fontSize(8).font('Helvetica').fillColor(C.text).text(`Rs ${inr(inv.amount)}`, R + 6, sy + 4, { width: RW - 6, align: 'center' });
    sy += 22;
    doc.fontSize(11).font('Helvetica-Bold').text('+', R + 6, sy, { width: RW, align: 'center' });
    sy = doc.y + 4;
    doc.rect(R + 6, sy, RW - 6, 15).fill('#FFFFFF');
    doc.fontSize(8).font('Helvetica').fillColor(C.text).text('Late Penalty Charges', R + 6, sy + 4, { width: RW - 6, align: 'center' });
    sy += 17;
    doc.fontSize(11).font('Helvetica-Bold').fillColor(C.text).text('Rs 0.00', R + 6, sy, { width: RW - 6, align: 'center' });
    sy = doc.y + 14;

    doc.moveTo(R + 6, sy).lineTo(R + RW, sy).lineWidth(1).strokeColor(C.text).stroke();
    sy += 6;
    doc.fontSize(8.5).font('Helvetica-Bold').text('PAYMENT DETAILS', R + 6, sy);
    sy = doc.y + 4;
    kv('Bank Name:', ISSUER.bank.name);
    kv('A/C No:', ISSUER.bank.account);
    kv('IFSC Code:', ISSUER.bank.ifsc);
    doc.fontSize(8).font('Helvetica-Bold').text('Authorized Signatory:', R + 6, sy);

    // ── Footer
    doc.rect(L, 700, LW, 22).fill(C.rowShade);
    doc.fontSize(9).font('Helvetica').fillColor(C.text).text('For any queries contact here ', L + 10, 707, { continued: true })
      .font('Helvetica-Bold').text(ISSUER.email);

    // Fixed Y positions: letting doc.y flow here would spill onto a new page.
    doc.moveTo(L, 752).lineTo(563, 752).lineWidth(1).strokeColor(C.text).stroke();
    doc.fontSize(7.5).font('Helvetica').fillColor(C.text)
      .text('This Bill is generated on behalf of', L, 758, { width: 190, lineBreak: false });
    doc.font('Helvetica-Bold').text(ISSUER.name, L, 769, { width: 200, lineBreak: false });
    doc.font('Helvetica').fontSize(7.5).text(ISSUER.office, 240, 758, { width: 320 });
    doc.font('Helvetica-Bold').text(`GSTIN: ${ISSUER.gstin}`, 240, 780, { width: 320, lineBreak: false });
  }

  // ── Page 2: meter readings + FAQs ─────────────────────────────────────────
  private page2(doc: PDFKit.PDFDocument, inv: any, plant: any, units: number) {
    const L = 32;
    const LW = 340;
    const R = 390;
    const RW = 173;

    doc.fontSize(9).font('Helvetica-Bold').fillColor(C.text).text(
      `SOLAR BILL OF SUPPLY  -  ${inv.period}  |  ${plant.legalName ?? plant.name}  |  ${ISSUER.name}`,
      L, 40, { width: 531, align: 'center' },
    );
    doc.moveTo(L, 66).lineTo(563, 66).lineWidth(1.4).strokeColor(C.text).stroke();

    doc.fontSize(11).font('Helvetica-Bold').text('METER READINGS', L, 82);

    // Site-level billing: one row for the plant's own cumulative counter.
    const headers = ['Meter', 'Start Reading', 'End Reading', 'Difference', 'MF', 'Adjustment', 'Total Units'];
    const widths = [58, 48, 48, 55, 26, 50, 55];
    let x = L;
    const top = 104;
    doc.rect(L, top, widths.reduce((a, b) => a + b, 0), 26).fill(C.rowShade);
    doc.fontSize(6.8).font('Helvetica-Bold').fillColor(C.text);
    headers.forEach((h, i) => {
      doc.text(h, x + 2, top + 8, { width: widths[i] - 4, align: 'center' });
      x += widths[i];
    });

    const diff = (inv.endReading ?? 0) - (inv.startReading ?? 0);
    const row = [
      plant.name,
      (inv.startReading ?? 0).toFixed(0),
      (inv.endReading ?? 0).toFixed(0),
      diff.toFixed(3),
      '1.00',
      '0.00',
      inr(units),
    ];
    x = L;
    const ry = top + 26;
    doc.fontSize(6.8).font('Helvetica').fillColor(C.text);
    row.forEach((v, i) => {
      doc.text(v, x + 2, ry + 8, { width: widths[i] - 4, align: 'center' });
      x += widths[i];
    });

    const tw = widths.reduce((a, b) => a + b, 0);
    const ty = ry + 26;
    doc.rect(L, ty, tw, 20).fill(C.highlight);
    doc.fontSize(7).font('Helvetica-Bold').fillColor(C.text);
    doc.text('Total generation', L + 2, ty + 7, { width: tw - widths[6] - 4, align: 'center' });
    doc.text(inr(units), L + tw - widths[6] + 2, ty + 7, { width: widths[6] - 4, align: 'center' });

    // Grid lines
    doc.lineWidth(0.6).strokeColor('#666666');
    for (let r = 0; r <= 3; r++) doc.moveTo(L, top + r * 26).lineTo(L + tw, top + r * 26).stroke();
    doc.moveTo(L, ty + 20).lineTo(L + tw, ty + 20).stroke();
    x = L;
    for (let i = 0; i <= widths.length; i++) {
      doc.moveTo(x, top).lineTo(x, ty).stroke();
      x += widths[i] ?? 0;
    }
    doc.moveTo(L, ty).lineTo(L, ty + 20).stroke();
    doc.moveTo(L + tw, ty).lineTo(L + tw, ty + 20).stroke();

    // ── FAQs sidebar
    doc.rect(R, 82, RW + 10, 420).fill(C.sidebar);
    let fy = 94;
    doc.fontSize(10).font('Helvetica-Bold').fillColor(C.text).text('FAQs', R + 8, fy);
    fy = doc.y + 8;
    const faqs: [string, string][] = [
      ['Generation Units', 'Energy generated by Solar Power Plant for the given invoice period as recorded by energy meters'],
      ['Adjustment Units', 'Units derived from alternative record (for example Inverter generation record) for the specific instances where deviation was observed in generation unit due to technical issues in the metering panel'],
      ['Tariff', 'Per unit agreed cost for billing for the invoice period as per Power Purchase Agreement'],
      ['Deemed Generation Units', 'Potential Units generated for periods when Solar Power Plant could not operate due to reasons un-attributable to the Power producer including but not limited to power outage, curtailment of solar generation with DG running etc'],
    ];
    for (const [h, b] of faqs) {
      doc.fontSize(8).font('Helvetica-Bold').fillColor(C.text).text(h, R + 8, fy, { width: RW - 8 });
      fy = doc.y + 2;
      doc.fontSize(7.5).font('Helvetica').fillColor(C.text).text(b, R + 8, fy, { width: RW - 8, align: 'justify' });
      fy = doc.y + 10;
    }
  }
}
