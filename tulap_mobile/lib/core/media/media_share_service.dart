import 'dart:io';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/geotag_camera/domain/entities/geotag_photo_entity.dart';

/// MediaShareService
/// ----------------------------------------------------------------------
/// Menangani pembagian berkas bukti kegiatan lapangan (Foto & Video)
/// dengan teks penjelasan kegiatan, waktu, dan lokasi dalam Bahasa Indonesia.
/// Membagikan file final ber-watermark (bukan file mentah internal).
/// ----------------------------------------------------------------------
class MediaShareService {
  Future<bool> shareEvidence({
    required GeotagPhotoEntity evidence,
    String? taskName,
  }) async {
    final file = File(evidence.localFilePath);
    if (!await file.exists()) {
      return false;
    }

    final df = DateFormat('dd MMMM yyyy • HH:mm', 'id_ID');
    final formattedDate = df.format(evidence.serverTimestamp);
    final locationText = evidence.address ??
        '${evidence.latitude.toStringAsFixed(6)}, ${evidence.longitude.toStringAsFixed(6)}';

    final buffer = StringBuffer();
    buffer.writeln('Dokumentasi Tulap.id');
    if (taskName != null && taskName.isNotEmpty) {
      buffer.writeln('Kegiatan: $taskName');
    }
    buffer.writeln('Tanggal: $formattedDate');
    buffer.writeln('Lokasi: $locationText');
    if (evidence.caption != null &&
        evidence.caption!.isNotEmpty &&
        evidence.caption != taskName) {
      buffer.writeln('Keterangan: ${evidence.caption}');
    }

    try {
      final xFile = XFile(
        evidence.localFilePath,
        mimeType: evidence.isVideo ? 'video/mp4' : 'image/jpeg',
      );

      final result = await Share.shareXFiles(
        [xFile],
        text: buffer.toString().trim(),
        subject: taskName ?? 'Dokumentasi Tulap.id',
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (_) {
      return false;
    }
  }
}
