/// ReportValidationResult
/// ----------------------------------------------------------------------
/// Hasil validasi data draf laporan sebelum diekspor ke PDF resmi.
/// Membedakan secara tegas antara:
/// - BLOCKER: masalah kritis yang menghalangi pembuatan PDF (mis. foto terpilih file fisiknya hilang).
/// - WARNING: informasi/peringatan non-blocking (mis. 1 video hanya ada di cloud, atau nota belum tersinkron).
/// ----------------------------------------------------------------------
class ReportValidationResult {
  final bool isReady;
  final List<String> blockers;
  final List<String> warnings;
  final int availableLocalMediaCount;
  final int missingLocalMediaCount;
  final int unconfirmedExpenseCount;

  const ReportValidationResult({
    required this.isReady,
    this.blockers = const [],
    this.warnings = const [],
    this.availableLocalMediaCount = 0,
    this.missingLocalMediaCount = 0,
    this.unconfirmedExpenseCount = 0,
  });

  bool get hasBlockers => blockers.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}
