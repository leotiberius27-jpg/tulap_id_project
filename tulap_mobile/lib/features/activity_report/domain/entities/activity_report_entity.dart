/// ActivityReportEntity
/// ----------------------------------------------------------------------
/// Entitas domain laporan kegiatan cerdas & LPJ foundation (Phase 8).
/// Mewakili satu hasil kompilasi laporan kegiatan resmi dalam format PDF
/// yang terikat ke satu Task SPPD, lengkap dengan versioning, snapshot,
/// dan integritas SHA-256.
/// ----------------------------------------------------------------------

enum ReportStatus {
  draft,
  ready,
  generating,
  generated,
  failed,
  archived;

  String get label {
    switch (this) {
      case ReportStatus.draft:
        return 'Draf';
      case ReportStatus.ready:
        return 'Siap Dibuat';
      case ReportStatus.generating:
        return 'Sedang Dibuat';
      case ReportStatus.generated:
        return 'Tersimpan';
      case ReportStatus.failed:
        return 'Gagal';
      case ReportStatus.archived:
        return 'Diarsipkan';
    }
  }

  static ReportStatus fromString(String val) {
    return ReportStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ReportStatus.generated,
    );
  }
}

class ActivityReportEntity {
  final String id;
  final String taskId;
  final String? userId;
  final String reportCode; // e.g. LAP-20260827-XXXX
  final String reportType; // e.g. ACTIVITY_REPORT, LPJ_SPPD, MONITORING_SURVEY
  final String templateId; // e.g. default_activity
  final int templateVersion;
  final String title;
  final String? summary;
  final String? narrative;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int versionNumber; // 1, 2, 3...
  final ReportStatus status;
  final String? pdfLocalPath;
  final String? pdfRemoteUrl;
  final String contentSnapshotJson; // Snapshot data saat laporan digenerate
  final String reportSha256; // SHA-256 checksum file PDF
  final double totalExpense;
  final int evidenceCount;
  final int receiptCount;
  final String syncStatus; // LOCAL_ONLY, SYNCED, PENDING
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? serverTimestamp;

  const ActivityReportEntity({
    required this.id,
    required this.taskId,
    this.userId,
    required this.reportCode,
    this.reportType = 'ACTIVITY_REPORT',
    this.templateId = 'default_activity',
    this.templateVersion = 1,
    required this.title,
    this.summary,
    this.narrative,
    this.periodStart,
    this.periodEnd,
    this.versionNumber = 1,
    this.status = ReportStatus.generated,
    this.pdfLocalPath,
    this.pdfRemoteUrl,
    required this.contentSnapshotJson,
    required this.reportSha256,
    this.totalExpense = 0.0,
    this.evidenceCount = 0,
    this.receiptCount = 0,
    this.syncStatus = 'LOCAL_ONLY',
    required this.createdAt,
    this.updatedAt,
    this.serverTimestamp,
  });

  String get formattedVersion => 'v$versionNumber';

  bool get isSynced => syncStatus == 'SYNCED';

  bool get hasLocalPdf => pdfLocalPath != null && pdfLocalPath!.isNotEmpty;
}
