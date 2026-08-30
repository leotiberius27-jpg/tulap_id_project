enum LpjPackageStatus {
  draft('Draf'),
  generated('Tercetak & Siap'),
  synced('Tersinkronisasi Cloud'),
  archived('Diarsipkan');

  final String label;
  const LpjPackageStatus(this.label);

  static LpjPackageStatus fromString(String? val) {
    if (val == null) return LpjPackageStatus.generated;
    final lower = val.toLowerCase();
    for (final s in LpjPackageStatus.values) {
      if (s.name.toLowerCase() == lower || s.label.toLowerCase() == lower) {
        return s;
      }
    }
    if (lower.contains('sync')) return LpjPackageStatus.synced;
    if (lower.contains('draft')) return LpjPackageStatus.draft;
    return LpjPackageStatus.generated;
  }
}

class LpjPackageEntity {
  final String id;
  final String travelMissionId;
  final String packageCode; // LPJ-20260828-XXXX
  final int versionNumber; // 1, 2, ...
  final String title;
  final String? pdfLocalPath;
  final String? pdfRemoteUrl;
  final String packageSha256;
  final double completenessScore; // 0.0 - 1.0
  final double totalActualExpense;
  final int activityCount;
  final int evidenceCount;
  final int receiptCount;
  final int documentCount;
  final String contentSnapshotJson;
  final LpjPackageStatus status;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LpjPackageEntity({
    required this.id,
    required this.travelMissionId,
    required this.packageCode,
    required this.versionNumber,
    required this.title,
    this.pdfLocalPath,
    this.pdfRemoteUrl,
    required this.packageSha256,
    required this.completenessScore,
    required this.totalActualExpense,
    this.activityCount = 0,
    this.evidenceCount = 0,
    this.receiptCount = 0,
    this.documentCount = 0,
    required this.contentSnapshotJson,
    this.status = LpjPackageStatus.generated,
    this.syncStatus = 'LOCAL_ONLY',
    required this.createdAt,
    this.updatedAt,
  });

  String get versionLabel => 'v$versionNumber';

  int get completenessPercentage => (completenessScore * 100).round();

  LpjPackageEntity copyWith({
    String? pdfLocalPath,
    String? pdfRemoteUrl,
    String? packageSha256,
    LpjPackageStatus? status,
    String? syncStatus,
    DateTime? updatedAt,
  }) {
    return LpjPackageEntity(
      id: id,
      travelMissionId: travelMissionId,
      packageCode: packageCode,
      versionNumber: versionNumber,
      title: title,
      pdfLocalPath: pdfLocalPath ?? this.pdfLocalPath,
      pdfRemoteUrl: pdfRemoteUrl ?? this.pdfRemoteUrl,
      packageSha256: packageSha256 ?? this.packageSha256,
      completenessScore: completenessScore,
      totalActualExpense: totalActualExpense,
      activityCount: activityCount,
      evidenceCount: evidenceCount,
      receiptCount: receiptCount,
      documentCount: documentCount,
      contentSnapshotJson: contentSnapshotJson,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
