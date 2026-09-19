import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Dilempar saat operasi Firebase Authentication gagal (email/password
/// atau Google) - membungkus [FirebaseAuthException.code] jadi pesan
/// berbahasa Indonesia siap-tampil, sambil tetap menyimpan [code] asli
/// untuk kebutuhan logging/debugging.
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

/// FirebaseEmailAuthService
/// ----------------------------------------------------------------------
/// Modul AUTENTIKASI FIREBASE BERDIRI SENDIRI (standalone) - SENGAJA
/// TIDAK terhubung ke alur login utama Tulap.id (LoginController +
/// backend NestJS/JWT di `features/auth`), yang tetap satu-satunya
/// sumber sesi resmi aplikasi produksi. Kelas ini melayani kebutuhan
/// terpisah yang secara eksplisit meminta Firebase Authentication
/// (Email/Password + Google) sebagai penyedia identitasnya sendiri.
///
/// Prasyarat:
///   - `Firebase.initializeApp()` sudah dipanggil (sudah terjadi di
///     `main.dart` sebelum `runApp()`), jadi `FirebaseAuth.instance` di
///     sini langsung siap dipakai tanpa init tambahan.
///   - Provider "Email/Password" dan "Google" sudah diaktifkan di
///     Firebase Console > Authentication > Sign-in method untuk project
///     `tulapid-dfaed`.
/// ----------------------------------------------------------------------
class FirebaseEmailAuthService {
  FirebaseEmailAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Emit setiap kali status login berubah (login, logout, token refresh).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromFirebaseException(e);
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromFirebaseException(e);
    }
  }

  /// Mengembalikan `null` jika user membatalkan dialog pemilihan akun -
  /// itu bukan kegagalan, sama seperti pola `OAuthSignInService`
  /// (`core/security/oauth_sign_in_service.dart`) yang sudah ada.
  Future<UserCredential?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
      accessToken: auth.accessToken,
    );

    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromFirebaseException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromFirebaseException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Sign-out lokal Google gagal (mis. belum pernah sign-in) tidak
      // dianggap fatal - sesi Firebase sendiri sudah dihapus di atas.
    }
  }
}
