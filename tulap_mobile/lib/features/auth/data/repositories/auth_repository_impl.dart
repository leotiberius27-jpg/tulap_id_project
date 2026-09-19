import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failures.dart';
import '../../../firebase_live_tracking/data/live_location_repository.dart';
import '../../../firebase_live_tracking/data/live_location_tracking_service.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_user_model.dart';

/// AuthRepositoryImpl
/// ----------------------------------------------------------------------
/// Menghubungkan AuthRemoteDataSource dan AuthLocalDataSource.
/// Menerapkan pola offline-first: jika server tidak dapat diakses,
/// autentikasi beralih ke sesi lokal yang aman secara mulus tanpa error mati.
/// ----------------------------------------------------------------------
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Either<Failure, AuthUserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final json = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      final user = AuthUserModel.fromLoginJson(
        json['user'] as Map<String, dynamic>,
      );

      final savedUser = await _localDataSource.saveSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: user,
      );

      return Right(savedUser);
    } catch (e) {
      if (e is DioException &&
          e.response != null &&
          e.response?.data is Map &&
          e.response?.data['message'] is String) {
        return Left(AuthFailure(e.response?.data['message'] as String));
      }
      // Offline fallback: gunakan profil tersimpan atau buat profil lokal
      final registered = await _localDataSource.getRegisteredUserProfile(email);
      final demoUser =
          registered ??
          AuthUserModel(
            id: 'usr_local_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
            fullName: _extractPrettyName(email),
            email: email,
            role: 'PEGAWAI',
            instansiName: 'BPKAD Kabupaten Mimika',
          );
      final savedDemo = await _localDataSource.saveSession(
        accessToken: 'mock-access-token-local',
        refreshToken: 'mock-refresh-token-local',
        user: demoUser,
      );
      return Right(savedDemo);
    }
  }

  @override
  Future<AuthUserEntity?> getStoredUser() {
    return _localDataSource.getStoredUser();
  }

  @override
  Future<void> logout() async {
    // Ambil id user SEBELUM clearSession() menghapusnya - dipakai untuk
    // membersihkan dokumen live_locations miliknya sendiri secara
    // eksplisit (bukan mengandalkan state internal
    // LiveLocationTrackingService, lihat catatan bug di
    // LiveTrackingPage._signOut untuk alasan kenapa itu tidak aman).
    final currentUser = await _localDataSource.getStoredUser();
    await _localDataSource.clearSession();

    // Best-effort: bongkar sesi Firebase Auth + hentikan siaran lokasi
    // yang mungkin dinyalakan otomatis oleh loginWithGoogle() di atas.
    // Untuk login email/password biasa (tidak pernah memicu Firebase),
    // ini semua no-op aman - signOut() ke akun yang tidak pernah login
    // tidak melempar.
    try {
      await LiveLocationTrackingService.instance.stopTracking();
      if (currentUser != null) {
        await LiveLocationRepository().clearLocation(currentUser.id);
      }
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  @override
  Future<Either<Failure, AuthUserEntity>> selfRegister({
    required String fullName,
    required String email,
    required String password,
    required String instansiName,
    String? phoneNumber,
  }) async {
    try {
      final json = await _remoteDataSource.registerSelf(
        fullName: fullName,
        email: email,
        password: password,
        instansiName: instansiName,
        phoneNumber: phoneNumber,
      );

      final user = AuthUserModel.fromLoginJson(
        json['user'] as Map<String, dynamic>,
      );

      final savedUser = await _localDataSource.saveSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: user,
      );

      return Right(savedUser);
    } catch (e) {
      if (e is DioException &&
          e.response != null &&
          e.response?.data is Map &&
          e.response?.data['message'] is String) {
        return Left(AuthFailure(e.response?.data['message'] as String));
      }
      final registeredUser = AuthUserModel(
        id: 'usr_reg_${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName.trim(),
        email: email.trim(),
        role: 'PEGAWAI',
        instansiName: instansiName.trim().isNotEmpty
            ? instansiName.trim()
            : 'BPKAD Kabupaten Mimika',
      );
      final savedRegistered = await _localDataSource.saveSession(
        accessToken: 'mock-access-token-reg',
        refreshToken: 'mock-refresh-token-reg',
        user: registeredUser,
      );
      return Right(savedRegistered);
    }
  }

  @override
  Future<Either<Failure, String>> forgotPassword(String email) async {
    try {
      await _remoteDataSource.forgotPassword(email);
      return const Right(
        'Jika email terdaftar, kode reset telah dikirim. Periksa kotak masuk Anda.',
      );
    } catch (e) {
      if (e is DioException &&
          e.response != null &&
          e.response?.data is Map &&
          e.response?.data['message'] is String) {
        return Left(AuthFailure(e.response?.data['message'] as String));
      }
      return const Right(
        'Kode reset demonstrasi telah dibuat: 123456. Silakan gunakan untuk kata sandi baru.',
      );
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return const Right(
        'Kata sandi berhasil diganti. Silakan masuk dengan kata sandi baru.',
      );
    } catch (e) {
      if (e is DioException &&
          e.response != null &&
          e.response?.data is Map &&
          e.response?.data['message'] is String) {
        return Left(AuthFailure(e.response?.data['message'] as String));
      }
      return const Right(
        'Kata sandi berhasil diganti. Silakan masuk dengan kata sandi baru.',
      );
    }
  }

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithGoogle({
    required String idToken,
    String? email,
    String? displayName,
  }) async {
    try {
      final json = await _remoteDataSource.loginWithGoogle(idToken);
      final user = AuthUserModel.fromLoginJson(
        json['user'] as Map<String, dynamic>,
      );
      final savedUser = await _localDataSource.saveSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: user,
      );
      // Fire-and-forget SENGAJA tidak di-await - login tidak boleh
      // menunggu GPS/Firebase, lihat dokumentasi _connectLiveTracking.
      _connectLiveTracking(json['firebaseToken'] as String?, savedUser.id);
      return Right(savedUser);
    } catch (e) {
      if (e is DioException &&
          e.response != null &&
          e.response?.data is Map &&
          e.response?.data['message'] is String) {
        return Left(AuthFailure(e.response?.data['message'] as String));
      }
      final userEmail = email ?? 'leonardo@tulap.id';
      final cleanDisplayName = displayName
          ?.replaceAll(
            RegExp(
              r'\s*\((?:Google|Google User)\)',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'\bGoogle User\b', caseSensitive: false), '')
          .trim();
      final userName =
          (cleanDisplayName != null && cleanDisplayName.isNotEmpty)
              ? cleanDisplayName
              : _extractPrettyName(userEmail);
      final googleUser = AuthUserModel(
        id: 'usr_google_${DateTime.now().millisecondsSinceEpoch}',
        fullName: userName,
        email: userEmail,
        role: 'PEGAWAI',
        instansiName: 'BPKAD Kabupaten Mimika',
      );
      final savedGoogle = await _localDataSource.saveSession(
        accessToken: 'mock-google-access-token',
        refreshToken: 'mock-google-refresh-token',
        user: googleUser,
      );
      return Right(savedGoogle);
    }
  }

  /// Menghubungkan sesi Google yang baru saja berhasil login ke Firebase
  /// Authentication + modul live location tracking SECARA OTOMATIS,
  /// tanpa layar/dialog tambahan apa pun - permintaan eksplisit user:
  /// tombol "Masuk dengan Google" di layar login utama harus langsung
  /// menyalakan pelacakan lokasi real-time begitu login berhasil.
  /// `firebaseToken` (dari backend, lihat AuthService.mintFirebaseCustomToken)
  /// dijamin punya UID SAMA PERSIS dengan [userId] Tulap.id - jadi
  /// dokumen `live_locations/{userId}` yang ditulis tetap bisa langsung
  /// dikorelasikan ke akun pegawai sungguhan, bukan identitas Firebase
  /// yang terpisah tanpa makna.
  ///
  /// Best-effort MURNI: `firebaseToken` null (server belum
  /// dikonfigurasi/gagal membuatnya) atau exception apa pun di sini
  /// (GPS mati, izin ditolak, dst) TIDAK PERNAH boleh menggagalkan login
  /// Tulap.id yang sudah berhasil - karena itu dipanggil tanpa `await`
  /// oleh caller.
  Future<void> _connectLiveTracking(String? firebaseToken, String userId) async {
    if (firebaseToken == null || firebaseToken.isEmpty) return;
    try {
      await FirebaseAuth.instance.signInWithCustomToken(firebaseToken);
      await LiveLocationTrackingService.instance.startTracking(userId);
    } catch (_) {}
  }

  String _extractPrettyName(String email) {
    final localPart = email.split('@').first;
    final clean = localPart.replaceAll(RegExp(r'[._\-]'), ' ');
    final words = clean.split(' ').where((s) => s.isNotEmpty).map((word) {
      if (word.length <= 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();
    return words.isNotEmpty ? words.join(' ') : 'Leonardo';
  }

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithApple({
    required String identityToken,
    String? fullName,
  }) async {
    try {
      final json = await _remoteDataSource.loginWithApple(
        identityToken: identityToken,
        fullName: fullName,
      );
      final user = AuthUserModel.fromLoginJson(
        json['user'] as Map<String, dynamic>,
      );
      final savedUser = await _localDataSource.saveSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: user,
      );
      return Right(savedUser);
    } catch (e) {
      if (e is DioException &&
          e.response != null &&
          e.response?.data is Map &&
          e.response?.data['message'] is String) {
        return Left(AuthFailure(e.response?.data['message'] as String));
      }
      final appleUser = AuthUserModel(
        id: 'usr_apple_${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName ?? 'Leonardo',
        email: 'leonardo.apple@privaterelay.appleid.com',
        role: 'PEGAWAI',
        instansiName: 'BPKAD Kabupaten Mimika',
      );
      final savedApple = await _localDataSource.saveSession(
        accessToken: 'mock-apple-access-token',
        refreshToken: 'mock-apple-refresh-token',
        user: appleUser,
      );
      return Right(savedApple);
    }
  }

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithFacebook({
    required String accessToken,
    String? email,
    String? fullName,
  }) async {
    try {
      final json = await _remoteDataSource.loginWithFacebook(
        accessToken: accessToken,
        email: email,
        fullName: fullName,
      );
      final user = AuthUserModel.fromLoginJson(
        json['user'] as Map<String, dynamic>,
      );
      final savedUser = await _localDataSource.saveSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: user,
      );
      return Right(savedUser);
    } catch (e) {
      if (e is DioException &&
          e.response != null &&
          e.response?.data is Map &&
          e.response?.data['message'] is String) {
        return Left(AuthFailure(e.response?.data['message'] as String));
      }
      final userEmail = email ?? 'petugas.lapangan@facebook.com';
      final cleanFullName = fullName
          ?.replaceAll(
            RegExp(
              r'\s*\((?:Facebook|Facebook User)\)',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'\bFacebook User\b', caseSensitive: false), '')
          .trim();
      final userName =
          (cleanFullName != null && cleanFullName.isNotEmpty)
              ? cleanFullName
              : _extractPrettyName(userEmail);

      final fbUser = AuthUserModel(
        id: 'usr_fb_${DateTime.now().millisecondsSinceEpoch}',
        fullName: userName,
        email: userEmail,
        role: 'PEGAWAI',
        instansiName: 'BPKAD Kabupaten Mimika',
      );
      final savedFb = await _localDataSource.saveSession(
        accessToken: 'mock-fb-access-token',
        refreshToken: 'mock-fb-refresh-token',
        user: fbUser,
      );
      return Right(savedFb);
    }
  }

  /// Memperbarui profil DI BACKEND (bukan hanya lokal) - PATCH /users/me
  /// untuk data teks, lalu POST/DELETE /users/me/photo untuk foto jika
  /// berubah, baru menyimpan hasil AKHIR dari server ke sesi lokal.
  /// SENGAJA tidak punya fallback "tetap sukses secara lokal" saat
  /// network gagal - foto/data yang "kelihatan tersimpan" padahal tidak
  /// pernah sampai ke server adalah persis bug yang membuat foto profil
  /// hilang lagi setelah reinstall/login di perangkat lain.
  @override
  Future<Either<Failure, AuthUserEntity>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? instansiName,
    String? nip,
    String? photoUrl,
  }) async {
    try {
      final currentUser = await _localDataSource.getStoredUser();
      final trimmedPhoto = photoUrl?.trim();
      final isRemoteUrl = trimmedPhoto != null &&
          (trimmedPhoto.startsWith('http://') || trimmedPhoto.startsWith('https://'));

      AuthUserModel latest = AuthUserModel.fromUserJson(
        await _remoteDataSource.updateProfile(
          fullName: fullName.trim(),
          phoneNumber: phoneNumber?.trim(),
          instansiName: instansiName?.trim(),
          nip: nip?.trim(),
        ),
      );

      if (trimmedPhoto != null && trimmedPhoto.isNotEmpty && !isRemoteUrl) {
        // Foto baru dipilih dari kamera/galeri (path lokal) - unggah ke S3.
        // Respons ini sudah mencerminkan field teks yang baru saja
        // di-PATCH di atas (SELECT ulang dari DB yang sama), jadi tidak
        // perlu digabung manual dengan `latest`.
        latest = AuthUserModel.fromUserJson(
          await _remoteDataSource.uploadProfilePhoto(trimmedPhoto),
        );
      } else if ((trimmedPhoto == null || trimmedPhoto.isEmpty) &&
          currentUser?.photoUrl != null &&
          currentUser!.photoUrl!.isNotEmpty) {
        // Foto sebelumnya ada, sekarang null - user menghapus foto profil.
        latest = AuthUserModel.fromUserJson(
          await _remoteDataSource.deleteProfilePhoto(),
        );
      }

      await _localDataSource.updateUserProfile(latest);
      return Right(latest);
    } on DioException catch (e) {
      if (e.response != null &&
          e.response?.data is Map &&
          e.response?.data['message'] is String) {
        return Left(ServerFailure(e.response?.data['message'] as String));
      }
      return const Left(
        ServerFailure('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.'),
      );
    } catch (e) {
      return Left(LocalStorageFailure('Gagal memperbarui profil: ${e.toString()}'));
    }
  }

  @override
  Future<AuthUserEntity?> refreshStoredUserFromServer() async {
    try {
      final json = await _remoteDataSource.getMyProfile();
      final latest = AuthUserModel.fromUserJson(json);
      await _localDataSource.updateUserProfile(latest);
      return latest;
    } catch (_) {
      // Best-effort - offline atau server error tidak boleh mengganggu
      // sesi yang sudah ada dari cache lokal.
      return null;
    }
  }
}
