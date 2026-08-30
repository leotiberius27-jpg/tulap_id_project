import 'dart:io';
import 'package:intl/intl.dart';
import '../../features/geotag_camera/domain/entities/camera_preferences_entity.dart';

/// FileNamingService
/// ----------------------------------------------------------------------
/// Menghasilkan nama file terstruktur untuk foto & video bukti lapangan.
/// - Menghilangkan karakter terlarang filesystem (/ \ : * ? " < > |)
/// - Menjaga integritas file tanpa tabrakan nama (collision protection)
/// - Membedakan nama file visual dari Evidence ID forensik (TL-YYYYMMDD-XXXX)
/// ----------------------------------------------------------------------
class FileNamingService {
  /// Membersihkan string dari karakter yang tidak valid untuk nama file
  String sanitize(String rawName) {
    if (rawName.trim().isEmpty) return 'Bukti_Lapangan';

    var clean = rawName.trim();
    // Hapus/ganti karakter ilegal filesystem
    clean = clean.replaceAll(RegExp(r'[\\/:*?"<>|#%&{}\\<>*?/$!\x27:@+`|=]'), '_');
    // Ganti spasi ganda atau pemisah menjadi underscore tunggal
    clean = clean.replaceAll(RegExp(r'\s+'), '_');
    clean = clean.replaceAll(RegExp(r'_+'), '_');

    // Hapus underscore di awal dan akhir
    clean = clean.replaceAll(RegExp(r'^_+|_+$'), '');

    if (clean.isEmpty) return 'Bukti_Lapangan';
    if (clean.length > 50) clean = clean.substring(0, 50);

    return clean;
  }

  /// Menghasilkan nama berkas foto/video sebelum disimpan
  String generateFilename({
    required FileNamingMode mode,
    required String taskName,
    required DateTime timestamp,
    required bool isVideo,
    String? customPrefix,
    int sequence = 1,
  }) {
    final ext = isVideo ? 'mp4' : 'jpg';
    final dateStr = DateFormat('yyyyMMdd').format(timestamp);
    final timeStr = DateFormat('HHmmss').format(timestamp);
    final seqStr = sequence.toString().padLeft(3, '0');

    if (mode == FileNamingMode.custom &&
        customPrefix != null &&
        customPrefix.trim().isNotEmpty) {
      final cleanPrefix = sanitize(customPrefix);
      return '${cleanPrefix}_${dateStr}_$seqStr.$ext';
    }

    final cleanTask = sanitize(taskName);
    return '${cleanTask}_${dateStr}_${timeStr}_$seqStr.$ext';
  }

  /// Memeriksa tabrakan file pada direktori dan mengembalikan path unik
  Future<String> resolveUniqueFilePath({
    required String directoryPath,
    required String baseFilename,
  }) async {
    var candidatePath = '$directoryPath/$baseFilename';
    if (!await File(candidatePath).exists()) {
      return candidatePath;
    }

    // Ekstrak nama dasar dan ekstensi
    final lastDot = baseFilename.lastIndexOf('.');
    final nameWithoutExt =
        lastDot != -1 ? baseFilename.substring(0, lastDot) : baseFilename;
    final ext = lastDot != -1 ? baseFilename.substring(lastDot) : '';

    var counter = 2;
    while (await File(candidatePath).exists()) {
      candidatePath = '$directoryPath/${nameWithoutExt}_$counter$ext';
      counter++;
    }

    return candidatePath;
  }
}
