import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Dibaca dari `--dart-define=GOOGLE_OAUTH_CLIENT_ID=...` /
/// `--dart-define=APPLE_OAUTH_CLIENT_ID=...` saat build - kredensial
/// OAuth ASLI dari Google Cloud Console / Apple Developer Program milik
/// instansi, TIDAK BOLEH ditebak/dibuat oleh kode ini (sama seperti pola
/// `_kApiBaseUrl` di injection_container.dart). Kosong secara default -
/// lihat OAuthSignInService untuk perilaku saat kredensial belum diisi.
const String kGoogleOAuthClientId = String.fromEnvironment(
  'GOOGLE_OAUTH_CLIENT_ID',
);
const String kAppleOAuthClientId = String.fromEnvironment(
  'APPLE_OAUTH_CLIENT_ID',
);

/// Redirect URI web khusus alur Sign In with Apple di ANDROID (iOS
/// memakai native ASAuthorizationController, tidak butuh ini) - harus
/// menunjuk ke halaman web yang di-hosting instansi yang meneruskan
/// balik ke app lewat deep link, lihat dokumentasi `sign_in_with_apple`.
const String kAppleOAuthRedirectUri = String.fromEnvironment(
  'APPLE_OAUTH_REDIRECT_URI',
);

class OAuthNotConfiguredException implements Exception {
  final String message;
  OAuthNotConfiguredException(this.message);
  @override
  String toString() => message;
}

/// OAuthSignInService
/// ----------------------------------------------------------------------
/// Membungkus SDK native Google/Apple Sign-In. Method ini memanggil SDK
/// SUNGGUHAN (google_sign_in/sign_in_with_apple) - TIDAK ada simulasi
/// atau hasil palsu. Jika Client ID belum dikonfigurasi, melempar
/// `OAuthNotConfiguredException` dengan pesan jelas SEBELUM memanggil
/// SDK sama sekali (SDK akan gagal dengan error native yang kurang
/// jelas bagi pengguna awam jika dibiarkan mencoba).
/// ----------------------------------------------------------------------
class OAuthSignInService {
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _google {
    return _googleSignIn ??= GoogleSignIn(
      serverClientId: kGoogleOAuthClientId.isEmpty
          ? null
          : kGoogleOAuthClientId,
      scopes: const ['email'],
    );
  }

  /// Mengembalikan informasi akun Google hasil autentikasi (idToken, email, displayName).
  /// Mencoba `signInSilently()` dulu - jika perangkat ini sudah pernah
  /// memberi izin ke Tulap.id untuk SATU akun Google tertentu (mis. bekas
  /// login sebelumnya), langsung masuk tanpa dialog pemilihan akun sama
  /// sekali. Dialog "Choose an account" (menampilkan SEMUA akun Google di
  /// perangkat) hanya muncul saat belum ada izin tersimpan itu - baik
  /// karena ini percobaan pertama, maupun setelah `signOutGoogle()`.
  /// Mengembalikan `null` jika user membatalkan dialog pemilihan akun -
  /// itu bukan kegagalan. Error lain (mis. Google Play Services / SHA-1
  /// belum terdaftar) dilempar apa adanya, TIDAK boleh dipalsukan jadi
  /// sukses - pemanggil (LoginController) yang menampilkan pesan error.
  Future<({String idToken, String? email, String? displayName})?>
  signInWithGoogle() async {
    GoogleSignInAccount? account;
    try {
      account = await _google.signInSilently();
    } catch (_) {
      account = null;
    }
    account ??= await _google.signIn();
    if (account == null) return null; // Dialog dibatalkan user

    final auth = await account.authentication;
    final token = auth.idToken;
    if (token == null) {
      throw Exception('Google tidak mengembalikan idToken.');
    }
    return (idToken: token, email: account.email, displayName: account.displayName);
  }

  /// Mengembalikan (identityToken, fullName) dari Sign In with Apple
  Future<({String identityToken, String? fullName})?> signInWithApple() async {
    if (kAppleOAuthClientId.isEmpty) {
      throw OAuthNotConfiguredException(
        'Masuk dengan Apple belum dikonfigurasi (APPLE_OAUTH_CLIENT_ID kosong).',
      );
    }
    if (!Platform.isIOS &&
        !Platform.isMacOS &&
        kAppleOAuthRedirectUri.isEmpty) {
      throw OAuthNotConfiguredException(
        'Masuk dengan Apple di Android butuh APPLE_OAUTH_REDIRECT_URI - belum dikonfigurasi.',
      );
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: (Platform.isIOS || Platform.isMacOS)
          ? null
          : WebAuthenticationOptions(
              clientId: kAppleOAuthClientId,
              redirectUri: Uri.parse(kAppleOAuthRedirectUri),
            ),
    );

    final fullName = [
      credential.givenName,
      credential.familyName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    return (
      identityToken: credential.identityToken!,
      fullName: fullName.isEmpty ? null : fullName,
    );
  }

  /// Mengembalikan (accessToken, email, displayName) dari Facebook Login.
  /// Facebook Login SDK (flutter_facebook_auth) BELUM dipasang - butuh
  /// App ID/Client Token asli dari Facebook Developer Console milik
  /// instansi (developers.facebook.com) plus setup native Android
  /// (meta-data di AndroidManifest.xml) sebelum bisa dipanggil sungguhan.
  /// Sebelumnya method ini SELALU mengembalikan identitas palsu yang
  /// di-hardcode ("petugas.lapangan@facebook.com") tanpa memanggil SDK
  /// apa pun - itu bug keamanan (siapapun bisa "login" tanpa akun
  /// Facebook asli). Sekarang gagal jujur dulu, sama seperti pola Apple.
  Future<({String accessToken, String? email, String? displayName})?>
  signInWithFacebook() async {
    throw OAuthNotConfiguredException(
      'Masuk dengan Facebook belum dikonfigurasi. Hubungi Admin.',
    );
  }

  Future<void> signOutGoogle() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Sign-out lokal Google gagal (mis. belum pernah sign-in) tidak
      // dianggap fatal - sesi Tulap.id sendiri tetap dihapus terpisah.
    }
  }
}
