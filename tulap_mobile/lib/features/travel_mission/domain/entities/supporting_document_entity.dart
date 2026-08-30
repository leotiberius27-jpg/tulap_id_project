enum SupportingDocumentType {
  assignmentLetter('Surat Tugas / Dasar Penugasan'),
  sppd('Lembar SPPD'),
  ticket('Tiket Perjalanan / Transportasi'),
  boardingPass('Boarding Pass'),
  hotelInvoice('Kuitansi / Invoice Penginapan'),
  receipt('Kuitansi / Bukti Bayar Langsung'),
  other('Dokumen Pendukung Lainnya');

  final String label;
  const SupportingDocumentType(this.label);

  static SupportingDocumentType fromString(String? val) {
    if (val == null) return SupportingDocumentType.other;
    final lower = val.toLowerCase();
    if (lower.contains('surat') || lower.contains('tugas') || lower.contains('assignment')) {
      return SupportingDocumentType.assignmentLetter;
    }
    if (lower.contains('sppd')) return SupportingDocumentType.sppd;
    if (lower.contains('tiket') || lower.contains('ticket')) return SupportingDocumentType.ticket;
    if (lower.contains('boarding')) return SupportingDocumentType.boardingPass;
    if (lower.contains('hotel') || lower.contains('penginapan') || lower.contains('lodging')) {
      return SupportingDocumentType.hotelInvoice;
    }
    if (lower.contains('receipt') || lower.contains('kuitansi') || lower.contains('nota')) {
      return SupportingDocumentType.receipt;
    }
    return SupportingDocumentType.other;
  }
}

class SupportingDocumentEntity {
  final String id;
  final String travelMissionId;
  final String? activityId;
  final SupportingDocumentType documentType;
  final String title;
  final String filePath;
  final String? remoteUrl;
  final String sha256;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SupportingDocumentEntity({
    required this.id,
    required this.travelMissionId,
    this.activityId,
    required this.documentType,
    required this.title,
    required this.filePath,
    this.remoteUrl,
    required this.sha256,
    this.syncStatus = 'LOCAL_ONLY',
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPdf => filePath.toLowerCase().endsWith('.pdf');

  SupportingDocumentEntity copyWith({
    String? title,
    String? filePath,
    String? remoteUrl,
    String? sha256,
    String? syncStatus,
    DateTime? updatedAt,
  }) {
    return SupportingDocumentEntity(
      id: id,
      travelMissionId: travelMissionId,
      activityId: activityId,
      documentType: documentType,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      sha256: sha256 ?? this.sha256,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
