/// StorageBreakdownEntity
/// ----------------------------------------------------------------------
/// Statistik penggunaan ruang penyimpanan lokal oleh Tulap.id.
/// Memisahkan secara transparan antara Database, Foto Bukti, Cache, dan Outbox.
/// ----------------------------------------------------------------------
class StorageBreakdownEntity {
  final int databaseBytes;
  final int photosBytes;
  final int cacheBytes;
  final int pendingUploadsCount;
  final int totalBytes;

  const StorageBreakdownEntity({
    required this.databaseBytes,
    required this.photosBytes,
    required this.cacheBytes,
    required this.pendingUploadsCount,
    required this.totalBytes,
  });

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedTotal => formatBytes(totalBytes);
  String get formattedDatabase => formatBytes(databaseBytes);
  String get formattedPhotos => formatBytes(photosBytes);
  String get formattedCache => formatBytes(cacheBytes);
}
