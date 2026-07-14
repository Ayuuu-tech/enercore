/// The documents Enercore requires before paying a vendor.
enum VendorDocType {
  panCard('PAN_CARD', 'PAN Card', 'Company or proprietor PAN'),
  gstCertificate('GST_CERTIFICATE', 'GST Certificate', 'GST registration certificate'),
  cancelledCheque('CANCELLED_CHEQUE', 'Cancelled Cheque', 'For bank account verification'),
  moa('MOA', 'MOA', 'Memorandum of Association'),
  aoa('AOA', 'AOA', 'Articles of Association');

  final String api;
  final String label;
  final String hint;
  const VendorDocType(this.api, this.label, this.hint);

  static VendorDocType fromApi(String v) =>
      VendorDocType.values.firstWhere((e) => e.api == v, orElse: () => VendorDocType.panCard);
}

class VendorDocument {
  final VendorDocType type;
  final String fileName;
  final int sizeBytes;
  final DateTime uploadedAt;

  const VendorDocument({
    required this.type,
    required this.fileName,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  factory VendorDocument.fromJson(Map<String, dynamic> j) => VendorDocument(
        type: VendorDocType.fromApi(j['type'] as String),
        fileName: j['fileName'] as String? ?? '',
        sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
        uploadedAt: DateTime.tryParse(j['uploadedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class VendorKyc {
  final String vendorId;
  final String companyName;

  /// NOT_SUBMITTED | PENDING | APPROVED | REJECTED
  final String status;
  final bool isVerified;
  final String? rejectReason;

  final String? pan;
  final String? gstin;
  final String? bankAccountName;

  /// Masked for the vendor ("••••9012"); admins get the full number.
  final String? bankAccountNumberMasked;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankName;

  final List<VendorDocument> documents;
  final List<VendorDocType> missingDocuments;
  final bool readyForReview;

  const VendorKyc({
    required this.vendorId,
    required this.companyName,
    required this.status,
    required this.isVerified,
    this.rejectReason,
    this.pan,
    this.gstin,
    this.bankAccountName,
    this.bankAccountNumberMasked,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankName,
    this.documents = const [],
    this.missingDocuments = const [],
    this.readyForReview = false,
  });

  bool hasDocument(VendorDocType t) => documents.any((d) => d.type == t);
  VendorDocument? documentFor(VendorDocType t) =>
      documents.where((d) => d.type == t).firstOrNull;

  factory VendorKyc.fromJson(Map<String, dynamic> j) => VendorKyc(
        vendorId: j['vendorId'] as String? ?? '',
        companyName: j['companyName'] as String? ?? '',
        status: j['kycStatus'] as String? ?? 'NOT_SUBMITTED',
        isVerified: j['isVerified'] as bool? ?? false,
        rejectReason: j['kycRejectReason'] as String?,
        pan: j['pan'] as String?,
        gstin: j['gstin'] as String?,
        bankAccountName: j['bankAccountName'] as String?,
        bankAccountNumberMasked: j['bankAccountNumberMasked'] as String?,
        bankAccountNumber: j['bankAccountNumber'] as String?,
        bankIfsc: j['bankIfsc'] as String?,
        bankName: j['bankName'] as String?,
        documents: (j['documents'] as List<dynamic>? ?? [])
            .map((d) => VendorDocument.fromJson(d as Map<String, dynamic>))
            .toList(),
        missingDocuments: (j['missingDocuments'] as List<dynamic>? ?? [])
            .map((d) => VendorDocType.fromApi(d as String))
            .toList(),
        readyForReview: j['readyForReview'] as bool? ?? false,
      );
}

/// A vendor's row in the admin KYC queue.
class VendorKycSummary {
  final String vendorId;
  final String companyName;
  final String contactName;
  final String email;
  final String status;
  final bool isVerified;
  final int documentCount;
  final int requiredCount;

  const VendorKycSummary({
    required this.vendorId,
    required this.companyName,
    required this.contactName,
    required this.email,
    required this.status,
    required this.isVerified,
    required this.documentCount,
    required this.requiredCount,
  });

  factory VendorKycSummary.fromJson(Map<String, dynamic> j) => VendorKycSummary(
        vendorId: j['vendorId'] as String? ?? '',
        companyName: j['companyName'] as String? ?? '',
        contactName: j['contactName'] as String? ?? '',
        email: j['email'] as String? ?? '',
        status: j['kycStatus'] as String? ?? 'NOT_SUBMITTED',
        isVerified: j['isVerified'] as bool? ?? false,
        documentCount: (j['documentCount'] as num?)?.toInt() ?? 0,
        requiredCount: (j['requiredCount'] as num?)?.toInt() ?? 5,
      );
}
