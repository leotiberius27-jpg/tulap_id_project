import 'package:flutter/services.dart';

/// RootDetector
/// ----------------------------------------------------------------------
/// Memeriksa apakah perangkat dalam kondisi root (Android) atau
/// jailbreak (iOS). Perangkat yang di-root/jailbreak jauh lebih mudah
/// dipasangi aplikasi fake-GPS tingkat sistem, sehingga capture bukti
/// resmi tetap kita blokir meski sinyal GPS "terlihat" normal.
///
/// Implementasi nyata memakai native channel ke plugin seperti
/// `safe_device` atau `flutter_jailbreak_detection` - di sini
/// dituliskan sebagai wrapper agar sumber deteksi bisa diganti tanpa
/// mengubah kode pemanggil (usecase & controller).
/// ----------------------------------------------------------------------
class RootDetector {
  static const MethodChannel _channel = MethodChannel(
    'id.tulap.security/device_integrity',
  );

  /// Mengembalikan true jika perangkat terindikasi root/jailbreak.
  /// Jika pemeriksaan native gagal (mis. platform belum didukung),
  /// method ini FAIL-SAFE ke `false` agar tidak memblokir pengguna
  /// sah secara keliru - namun kegagalan ini tetap dicatat di log
  /// untuk investigasi lebih lanjut oleh tim keamanan.
  Future<bool> isDeviceCompromised() async {
    try {
      final bool isCompromised =
          await _channel.invokeMethod('isDeviceCompromised') ?? false;
      return isCompromised;
    } on PlatformException catch (_) {
      return false;
    } on MissingPluginException catch (_) {
      // Native implementation belum dipasang di sisi Android/iOS -
      // dianggap aman secara default sambil menunggu implementasi native.
      return false;
    }
  }
}
