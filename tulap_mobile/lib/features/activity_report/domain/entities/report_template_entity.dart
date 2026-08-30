/// ReportTemplateEntity
/// ----------------------------------------------------------------------
/// Konfigurasi tata letak dan elemen presentasi untuk laporan kegiatan PDF.
/// Memisahkan secara tegas antara DATA LAPORAN dan PRESENTASI LAPORAN.
/// ----------------------------------------------------------------------

enum PhotoLayoutOption {
  twoPerPage(2, '2 Foto per Halaman (Rekomendasi)'),
  fourPerPage(4, '4 Foto per Halaman (Kompak)'),
  onePerPage(1, '1 Foto per Halaman (Detail Penuh)');

  final int count;
  final String label;
  const PhotoLayoutOption(this.count, this.label);
}

class ReportTemplateEntity {
  final String id;
  final String name;
  final String description;
  final int version;
  final bool showCover;
  final bool showHeader;
  final bool showTimeline;
  final bool showExpenses;
  final bool showReceipts;
  final bool showVerification;
  final bool showNotes;
  final bool showSignatures;
  final PhotoLayoutOption photoLayout;
  final String? institutionName;
  final String? workUnit;
  final String? logoAsset;

  const ReportTemplateEntity({
    required this.id,
    required this.name,
    required this.description,
    this.version = 1,
    this.showCover = false,
    this.showHeader = true,
    this.showTimeline = true,
    this.showExpenses = true,
    this.showReceipts = true,
    this.showVerification = true,
    this.showNotes = true,
    this.showSignatures = true,
    this.photoLayout = PhotoLayoutOption.twoPerPage,
    this.institutionName,
    this.workUnit,
    this.logoAsset,
  });

  /// Template default standar administratif pemerintah Indonesia
  static const defaultActivity = ReportTemplateEntity(
    id: 'default_activity',
    name: 'Laporan Kegiatan Lapangan (Standar)',
    description: 'Format resmi lengkap: Info Kegiatan, Ringkasan, Kronologi, Dokumentasi Foto/Video, Rekapitulasi Nota, & Lembar Pengesahan.',
    version: 1,
    showCover: false,
    showHeader: true,
    showTimeline: true,
    showExpenses: true,
    showReceipts: true,
    showVerification: true,
    showNotes: true,
    showSignatures: true,
    photoLayout: PhotoLayoutOption.twoPerPage,
  );

  /// Template ringkas (Quick Field Report)
  static const compactReport = ReportTemplateEntity(
    id: 'compact_activity',
    name: 'Laporan Ringkas / Monitoring',
    description: 'Format ringkas: Ringkasan narasi & dokumentasi foto kompak (4 foto per halaman).',
    version: 1,
    showCover: false,
    showHeader: true,
    showTimeline: false,
    showExpenses: false,
    showReceipts: false,
    showVerification: true,
    showNotes: false,
    showSignatures: true,
    photoLayout: PhotoLayoutOption.fourPerPage,
  );

  /// Template LPJ / Keuangan (Financial Focus)
  static const financialLpj = ReportTemplateEntity(
    id: 'financial_lpj',
    name: 'Laporan Realisasi Anggaran & Nota (LPJ Foundation)',
    description: 'Fokus pembuktian keuangan: Tabel rincian pengeluaran lengkap dan lampiran nota fisik yang terbaca jelas.',
    version: 1,
    showCover: false,
    showHeader: true,
    showTimeline: false,
    showExpenses: true,
    showReceipts: true,
    showVerification: true,
    showNotes: true,
    showSignatures: true,
    photoLayout: PhotoLayoutOption.twoPerPage,
  );

  ReportTemplateEntity copyWith({
    String? id,
    String? name,
    String? description,
    int? version,
    bool? showCover,
    bool? showHeader,
    bool? showTimeline,
    bool? showExpenses,
    bool? showReceipts,
    bool? showVerification,
    bool? showNotes,
    bool? showSignatures,
    PhotoLayoutOption? photoLayout,
    String? institutionName,
    String? workUnit,
    String? logoAsset,
  }) {
    return ReportTemplateEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      showCover: showCover ?? this.showCover,
      showHeader: showHeader ?? this.showHeader,
      showTimeline: showTimeline ?? this.showTimeline,
      showExpenses: showExpenses ?? this.showExpenses,
      showReceipts: showReceipts ?? this.showReceipts,
      showVerification: showVerification ?? this.showVerification,
      showNotes: showNotes ?? this.showNotes,
      showSignatures: showSignatures ?? this.showSignatures,
      photoLayout: photoLayout ?? this.photoLayout,
      institutionName: institutionName ?? this.institutionName,
      workUnit: workUnit ?? this.workUnit,
      logoAsset: logoAsset ?? this.logoAsset,
    );
  }
}
