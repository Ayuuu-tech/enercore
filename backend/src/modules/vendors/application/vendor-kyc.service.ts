import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { KycStatus, VendorDocumentType } from '@prisma/client';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { BlobStorageService } from '../../../common/storage/blob-storage.service';

/** Documents Enercore requires before a vendor can be paid. */
export const REQUIRED_DOCUMENTS: VendorDocumentType[] = [
  'PAN_CARD',
  'GST_CERTIFICATE',
  'CANCELLED_CHEQUE',
  'MOA',
  'AOA',
];

const MAX_FILE_BYTES = 10 * 1024 * 1024; // 10 MB
const ALLOWED_MIME = ['application/pdf', 'image/jpeg', 'image/png'];

// A wrong IFSC or account number sends money to the wrong bank, and a
// malformed PAN/GSTIN fails at filing time. Cheap to check, expensive to miss.
const PAN_RE = /^[A-Z]{5}[0-9]{4}[A-Z]$/;
const GSTIN_RE = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z][Z][0-9A-Z]$/;
const IFSC_RE = /^[A-Z]{4}0[A-Z0-9]{6}$/;
const ACCOUNT_RE = /^[0-9]{9,18}$/;

export interface KycDetails {
  pan: string;
  gstin: string;
  bankAccountName: string;
  bankAccountNumber: string;
  bankIfsc: string;
  bankName: string;
}

@Injectable()
export class VendorKycService {
  private readonly logger = new Logger(VendorKycService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: BlobStorageService,
  ) {}

  private async vendorOrThrow(vendorId: string) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: { documents: true },
    });
    if (!vendor) throw new NotFoundException('Vendor profile not found');
    return vendor;
  }

  /** A vendor may only touch their own KYC; admins may see any. */
  private assertOwner(vendorId: string, userId: string, role: string) {
    if (role !== 'ADMIN' && vendorId !== userId) {
      throw new ForbiddenException('You can only access your own KYC');
    }
  }

  /** Saves the vendor's identity and bank details, and moves KYC to PENDING. */
  async saveDetails(vendorId: string, d: KycDetails) {
    const pan = d.pan?.trim().toUpperCase();
    const gstin = d.gstin?.trim().toUpperCase();
    const ifsc = d.bankIfsc?.trim().toUpperCase();
    const account = d.bankAccountNumber?.trim();

    if (!PAN_RE.test(pan ?? '')) {
      throw new BadRequestException('PAN must look like ABCDE1234F');
    }
    if (!GSTIN_RE.test(gstin ?? '')) {
      throw new BadRequestException('GSTIN must be a valid 15-character GST number');
    }
    if (!IFSC_RE.test(ifsc ?? '')) {
      throw new BadRequestException('IFSC must look like HDFC0001234');
    }
    if (!ACCOUNT_RE.test(account ?? '')) {
      throw new BadRequestException('Bank account number must be 9–18 digits');
    }
    if (!d.bankAccountName?.trim()) {
      throw new BadRequestException('Account holder name is required');
    }

    await this.vendorOrThrow(vendorId);

    return this.prisma.vendor.update({
      where: { id: vendorId },
      data: {
        pan,
        gstin,
        bankIfsc: ifsc,
        bankAccountNumber: account,
        bankAccountName: d.bankAccountName.trim(),
        bankName: d.bankName?.trim() || null,
        // Details changed, so it needs looking at again.
        kycStatus: KycStatus.PENDING,
        kycSubmittedAt: new Date(),
        kycRejectReason: null,
      },
    });
  }

  async uploadDocument(
    vendorId: string,
    type: VendorDocumentType,
    file: { buffer: Buffer; originalname: string; mimetype: string; size: number },
  ) {
    if (!file) throw new BadRequestException('No file uploaded');
    if (file.size > MAX_FILE_BYTES) {
      throw new BadRequestException('File must be 10 MB or smaller');
    }
    if (!ALLOWED_MIME.includes(file.mimetype)) {
      throw new BadRequestException('File must be a PDF, JPEG or PNG');
    }

    const vendor = await this.vendorOrThrow(vendorId);

    // Re-uploading a document replaces the old one, so a vendor can fix a bad
    // scan without leaving both versions behind.
    const existing = vendor.documents.find((d) => d.type === type);
    if (existing) {
      await this.storage.delete(existing.blobKey).catch((e) =>
        this.logger.warn(`Could not delete replaced blob ${existing.blobKey}: ${e}`),
      );
    }

    const ext = file.originalname.split('.').pop()?.toLowerCase() ?? 'bin';
    const blobKey = `${vendorId}/${type}-${Date.now()}.${ext}`;
    await this.storage.upload(blobKey, file.buffer, file.mimetype);

    await this.prisma.vendorDocument.upsert({
      where: { vendorId_type: { vendorId, type } },
      update: {
        blobKey,
        fileName: file.originalname,
        mimeType: file.mimetype,
        sizeBytes: file.size,
        uploadedAt: new Date(),
      },
      create: {
        vendorId,
        type,
        blobKey,
        fileName: file.originalname,
        mimeType: file.mimetype,
        sizeBytes: file.size,
      },
    });

    // A new document means the submission needs re-reviewing.
    await this.prisma.vendor.update({
      where: { id: vendorId },
      data: {
        kycStatus: KycStatus.PENDING,
        kycSubmittedAt: new Date(),
        kycRejectReason: null,
      },
    });

    return this.getStatus(vendorId);
  }

  /** KYC as the vendor (or an admin) sees it, including what's still missing. */
  async getStatus(vendorId: string) {
    const v = await this.vendorOrThrow(vendorId);
    const uploaded = v.documents.map((d) => d.type);
    const missing = REQUIRED_DOCUMENTS.filter((t) => !uploaded.includes(t));

    return {
      vendorId: v.id,
      companyName: v.companyName,
      kycStatus: v.kycStatus,
      isVerified: v.isVerified,
      kycSubmittedAt: v.kycSubmittedAt,
      kycReviewedAt: v.kycReviewedAt,
      kycRejectReason: v.kycRejectReason,
      pan: v.pan,
      gstin: v.gstin,
      bankAccountName: v.bankAccountName,
      // Only the last 4 digits go back over the wire — the full number is only
      // ever needed by whoever actually makes the payout.
      bankAccountNumberMasked: v.bankAccountNumber
        ? `••••${v.bankAccountNumber.slice(-4)}`
        : null,
      bankIfsc: v.bankIfsc,
      bankName: v.bankName,
      documents: v.documents.map((d) => ({
        type: d.type,
        fileName: d.fileName,
        sizeBytes: d.sizeBytes,
        uploadedAt: d.uploadedAt,
      })),
      requiredDocuments: REQUIRED_DOCUMENTS,
      missingDocuments: missing,
      /** Everything Enercore needs in order to review. */
      readyForReview: missing.length === 0 && !!v.pan && !!v.bankAccountNumber,
    };
  }

  /** A short-lived link to one document. */
  async documentUrl(vendorId: string, type: VendorDocumentType, userId: string, role: string) {
    this.assertOwner(vendorId, userId, role);
    const doc = await this.prisma.vendorDocument.findUnique({
      where: { vendorId_type: { vendorId, type } },
    });
    if (!doc) throw new NotFoundException('Document not uploaded');
    return { url: await this.storage.signedUrl(doc.blobKey), fileName: doc.fileName };
  }

  // ── Admin review ──────────────────────────────────────────────────────────

  /** Every vendor's KYC, for the admin queue. */
  async listForAdmin() {
    const vendors = await this.prisma.vendor.findMany({
      include: { documents: true, user: { select: { name: true, email: true } } },
      orderBy: { kycSubmittedAt: 'desc' },
    });
    return vendors.map((v) => ({
      vendorId: v.id,
      companyName: v.companyName,
      contactName: v.user.name,
      email: v.user.email,
      kycStatus: v.kycStatus,
      isVerified: v.isVerified,
      kycSubmittedAt: v.kycSubmittedAt,
      documentCount: v.documents.length,
      requiredCount: REQUIRED_DOCUMENTS.length,
    }));
  }

  /** Admin sees the full, unmasked detail in order to actually verify it. */
  async getForAdmin(vendorId: string) {
    const v = await this.vendorOrThrow(vendorId);
    const status = await this.getStatus(vendorId);
    return { ...status, bankAccountNumber: v.bankAccountNumber };
  }

  async approve(vendorId: string) {
    const status = await this.getStatus(vendorId);
    if (!status.readyForReview) {
      throw new BadRequestException(
        `Cannot approve: missing ${status.missingDocuments.join(', ') || 'bank/PAN details'}`,
      );
    }
    this.logger.log(`KYC approved for vendor ${vendorId}`);
    return this.prisma.vendor.update({
      where: { id: vendorId },
      data: {
        kycStatus: KycStatus.APPROVED,
        isVerified: true,
        kycReviewedAt: new Date(),
        kycRejectReason: null,
      },
    });
  }

  async reject(vendorId: string, reason: string) {
    if (!reason?.trim()) {
      throw new BadRequestException('A rejection reason is required — the vendor has to know what to fix');
    }
    await this.vendorOrThrow(vendorId);
    return this.prisma.vendor.update({
      where: { id: vendorId },
      data: {
        kycStatus: KycStatus.REJECTED,
        isVerified: false,
        kycReviewedAt: new Date(),
        kycRejectReason: reason.trim(),
      },
    });
  }
}
