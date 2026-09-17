import 'dart:io';
import '../../features/geotag_camera/domain/entities/geotag_photo_entity.dart';

/// MediaThumbnailService
/// ----------------------------------------------------------------------
/// Layanan manajemen cache thumbnail foto & representasi video.
/// Mengoptimalkan pemuatan daftar galeri besar (100+ item) secara efisien
/// dan mencegah spike memori RAM pada perangkat seluler.
/// ----------------------------------------------------------------------
class MediaThumbnailService {
  final Map<String, String> _thumbnailCache = {};

  /// Mendapatkan path file thumbnail lokal atau fallback ke localFilePath
  String getThumbnailPath(GeotagPhotoEntity evidence) {
    if (_thumbnailCache.containsKey(evidence.id)) {
      return _thumbnailCache[evidence.id]!;
    }
    return evidence.localFilePath;
  }

  /// Memeriksa ketersediaan file media di perangkat lokal
  bool isLocalMediaAvailable(GeotagPhotoEntity evidence) {
    if (evidence.localFilePath.startsWith('http://') ||
        evidence.localFilePath.startsWith('https://') ||
        evidence.localFilePath.startsWith('assets/')) {
      return true;
    }
    final file = File(evidence.localFilePath);
    return file.existsSync();
  }

  /// Membersihkan cache thumbnail
  void clearCache() {
    _thumbnailCache.clear();
  }
}
