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
  /// Menghitung SHA-256 dari file di [filePath] dan mengembalikan
  /// representasi hex string-nya.
  Future<String> generateSha256(String filePath) async {
    final file = File(filePath);
    final Uint8List bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
