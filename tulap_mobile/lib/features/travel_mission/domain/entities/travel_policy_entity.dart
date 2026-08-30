import 'supporting_document_entity.dart';

class TravelChecklistItemConfig {
  final String id;
  final String label;
  final String description;
  final bool isMandatory;
  final String validationCategory; // 'assignment', 'activity', 'evidence', 'expense', 'document', 'report'
  final SupportingDocumentType? requiredDocType;

  const TravelChecklistItemConfig({
    required this.id,
    required this.label,
    required this.description,
    required this.isMandatory,
    required this.validationCategory,
    this.requiredDocType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'description': description,
    'isMandatory': isMandatory,
    'validationCategory': validationCategory,
    'requiredDocType': requiredDocType?.name,
  };

  factory TravelChecklistItemConfig.fromJson(Map<String, dynamic> json) {
    return TravelChecklistItemConfig(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
      isMandatory: json['isMandatory'] as bool? ?? true,
      validationCategory: json['validationCategory'] as String? ?? 'document',
      requiredDocType: json['requiredDocType'] != null
          ? SupportingDocumentType.values.firstWhere(
              (e) => e.name == json['requiredDocType'],
              orElse: () => SupportingDocumentType.other,
            )
          : null,
    );
  }
}

class TravelPolicyEntity {
  final String id;
  final String? organizationId;
  final String policyName;
  final bool requireAssignmentLetter;
  final bool requireActivity;
  final bool requireEvidencePhoto;
  final bool requireExpenseReceipt;
  final bool requireTicketIfFlight;
  final bool requireActivityReport;
  final List<TravelChecklistItemConfig> customChecklist;

  const TravelPolicyEntity({
    required this.id,
    this.organizationId,
    required this.policyName,
    this.requireAssignmentLetter = true,
    this.requireActivity = true,
    this.requireEvidencePhoto = true,
    this.requireExpenseReceipt = true,
    this.requireTicketIfFlight = true,
    this.requireActivityReport = true,
    this.customChecklist = const [],
  });

  /// Default neutral policy for general public sector field trips
  static const TravelPolicyEntity standard = TravelPolicyEntity(
    id: 'standard_policy',
    policyName: 'Kebijakan Standar Perjalanan Dinas',
    requireAssignmentLetter: true,
    requireActivity: true,
    requireEvidencePhoto: true,
    requireExpenseReceipt: true,
    requireTicketIfFlight: true,
    requireActivityReport: true,
    customChecklist: [
      TravelChecklistItemConfig(
        id: 'req_assignment_letter',
        label: 'Surat Tugas / Dasar Penugasan',
        description: 'Nomor, tanggal surat, dan lampiran surat tugas resmi',
        isMandatory: true,
        validationCategory: 'assignment',
        requiredDocType: SupportingDocumentType.assignmentLetter,
      ),
      TravelChecklistItemConfig(
        id: 'req_travel_info',
        label: 'Data Lengkap Perjalanan & Personil',
        description: 'Asal, tujuan, tanggal, moda transportasi & personil snapshot',
        isMandatory: true,
        validationCategory: 'travel_info',
      ),
      TravelChecklistItemConfig(
        id: 'req_min_activity',
        label: 'Kegiatan Lapangan Terhubung',
        description: 'Minimal 1 aktivitas/kegiatan terhubung ke misi perjalanan',
        isMandatory: true,
        validationCategory: 'activity',
      ),
      TravelChecklistItemConfig(
        id: 'req_evidence_photos',
        label: 'Dokumentasi Foto Geotag Bukti',
        description: 'Foto kegiatan lapangan dengan watermark lokasi & waktu',
        isMandatory: true,
        validationCategory: 'evidence',
      ),
      TravelChecklistItemConfig(
        id: 'req_expense_receipts',
        label: 'Rekapitulasi Biaya & Nota Pengeluaran',
        description: 'Kuitansi/nota riil hasil scan & konfirmasi nominal',
        isMandatory: true,
        validationCategory: 'expense',
      ),
      TravelChecklistItemConfig(
        id: 'req_ticket_boarding',
        label: 'Tiket Perjalanan / Boarding Pass',
        description: 'Bukti tiket/boarding pass jika menggunakan moda transportasi umum/pesawat',
        isMandatory: false,
        validationCategory: 'document',
        requiredDocType: SupportingDocumentType.ticket,
      ),
      TravelChecklistItemConfig(
        id: 'req_activity_report',
        label: 'Laporan Ringkas Hasil Kegiatan',
        description: 'Laporan naratif pelaksanaan kegiatan lapangan',
        isMandatory: true,
        validationCategory: 'report',
      ),
    ],
  );
}
