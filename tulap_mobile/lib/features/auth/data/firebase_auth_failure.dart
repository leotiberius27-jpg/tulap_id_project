import 'package:firebase_auth/firebase_auth.dart';

/// Dilempar saat operasi Firebase Authentication gagal (email/password
/// atau Google) - membungkus [FirebaseAuthException.code] jadi pesan
/// berbahasa Indonesia siap-tampil, sambil tetap menyimpan [code] asli
/// untuk kebutuhan logging/debugging. Dipakai AuthRepositoryImpl untuk
/// login "pintu depan" (lihat AuthService.loginWithFirebase di backend).
class FirebaseAuthFailure implements Exception {
  final String code;
  final String message;
  const FirebaseAuthFailure(this.code, this.message);

  factory FirebaseAuthFailure.fromFirebaseException(FirebaseAuthException e) {
    final message = switch (e.code) {
      'invalid-email' => 'Format email tidak valid.',
      'user-disabled' => 'Akun ini telah dinonaktifkan.',
      'user-not-found' => 'Akun dengan email ini tidak ditemukan.',
      'wrong-password' ||
      'invalid-credential' => 'Email atau kata sandi salah.',
      'email-already-in-use' => 'Email ini sudah terdaftar.',
      'weak-password' => 'Kata sandi terlalu lemah (minimal 6 karakter).',
      'operation-not-allowed' =>
        'Metode masuk ini belum diaktifkan di Firebase Console.',
      'too-many-requests' =>
        'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.',
      'network-request-failed' => 'Tidak ada koneksi internet.',
      _ => e.message ?? 'Autentikasi gagal (${e.code}).',
    };
    return FirebaseAuthFailure(e.code, message);
  }

  @override
  String toString() => message;
}
