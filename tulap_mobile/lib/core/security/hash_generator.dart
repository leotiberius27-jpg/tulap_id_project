import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// HashGenerator
/// ----------------------------------------------------------------------
/// Menghasilkan checksum SHA-256 dari file foto ASLI (sebelum kompresi)
/// sebagai bukti integritas - hash ini nantinya dikirim & disimpan di
/// kolom `integrityHash` pada tabel Geotag_Photo di backend.
///
/// PENTING: hash harus dihitung dari byte file gambar mentah SEBELUM
/// proses kompresi (ImageCompressor) dijalankan, karena kompresi
/// mengubah byte file. Urutan yang benar di usecase:
///   1. Capture foto mentah dari kamera
///   2. Hitung SHA-256 dari file mentah ini (HashGenerator)
///   3. Baru kompresi untuk keperluan upload (ImageCompressor)
/// Hash mentah tetap disimpan sebagai bukti file ASLI belum dimanipulasi
/// pada saat pengambilan, terlepas dari kompresi yang terjadi setelahnya.
/// ----------------------------------------------------------------------
class HashGenerator {
  /// Menghitung SHA-256 dari file di [filePath] menggunakan streaming
  /// (chunked reading) agar tidak membebani memori RAM pada file video/foto besar.
  Future<String> generateSha256(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File bukti tidak ditemukan', filePath);
    }
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString();
  }

  /// Menghitung SHA-256 langsung dari raw byte buffer
  String generateSha256FromBytes(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }
}
