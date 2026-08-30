// Smoke test: app should boot to the Login screen when no session is
// stored, without needing the real database/secure-storage plugins.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tulap_mobile/app/di/injection_container.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/core/localization/app_language.dart';
import 'package:tulap_mobile/core/localization/language_controller.dart';
import 'package:tulap_mobile/core/network/network_info.dart';
import 'package:tulap_mobile/core/security/biometric_auth_service.dart';
import 'package:tulap_mobile/core/session/auth_session_manager.dart';
import 'package:tulap_mobile/core/theme/app_theme_mode.dart';
import 'package:tulap_mobile/core/theme/theme_controller.dart';
import 'package:tulap_mobile/features/account/data/datasources/account_local_datasource.dart';
import 'package:tulap_mobile/features/account/domain/entities/account_settings_entity.dart';
import 'package:tulap_mobile/features/account/domain/entities/storage_breakdown_entity.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_biometric_greeting_user.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/restore_biometric_session.dart';
import 'package:tulap_mobile/core/security/oauth_sign_in_service.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/is_biometric_login_enabled.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login_with_apple.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login_with_facebook.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login_with_google.dart';
import 'package:tulap_mobile/main.dart';

class _FakeOAuthSignInService implements OAuthSignInService {
  @override
  Future<({String idToken, String? email, String? displayName})?>
  signInWithGoogle() async => null;

  @override
  Future<({String identityToken, String? fullName})?>
  signInWithApple() async => null;

  @override
  Future<({String accessToken, String? email, String? displayName})?>
  signInWithFacebook() async => null;

  @override
  Future<void> signOutGoogle() async {}
}

/// Menghindari MissingPluginException dari `connectivity_plus` di
/// lingkungan widget test (tidak ada platform channel sungguhan) -
/// WelcomePage butuh NetworkInfo untuk pill "Online/Offline".
class _FakeNetworkInfo extends NetworkInfo {
  _FakeNetworkInfo() : super(Connectivity());

  @override
  Future<bool> get isConnected async => true;
}

class _NoSessionAuthRepository implements AuthRepository {
  @override
  Future<AuthUserEntity?> getStoredUser() async => null;

  @override
  Future<Either<Failure, AuthUserEntity>> login({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<Either<Failure, AuthUserEntity>> selfRegister({
    required String fullName,
    required String email,
    required String password,
    required String instansiName,
    String? phoneNumber,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> forgotPassword(String email) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithGoogle({
    required String idToken,
    String? email,
    String? displayName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithApple({
    required String identityToken,
    String? fullName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithFacebook({
    required String accessToken,
    String? email,
    String? fullName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isBiometricLoginEnabled() async => false;

  @override
  Future<void> enableBiometricLogin() async {}

  @override
  Future<void> disableBiometricLogin() async {}

  @override
  Future<AuthUserEntity?> getBiometricGreetingUser() async => null;

  @override
  Future<AuthUserEntity?> restoreBiometricSession() async => null;

  @override
  Future<Either<Failure, AuthUserEntity>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? instansiName,
    String? nip,
    String? photoUrl,
  }) async => throw UnimplementedError();
}

class _FakeAccountLocalDataSource implements AccountLocalDataSource {
  @override
  Future<AppThemeMode> getThemeMode() async => AppThemeMode.system;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {}

  @override
  Future<AppLanguage> getLanguage() async => AppLanguage.id;

  @override
  Future<void> saveLanguage(AppLanguage language) async {}

  @override
  Future<CameraSettingsEntity> getCameraSettings() async => const CameraSettingsEntity();

  @override
  Future<void> saveCameraSettings(CameraSettingsEntity settings) async {}

  @override
  Future<NotificationSettingsEntity> getNotificationSettings() async =>
      const NotificationSettingsEntity();

  @override
  Future<void> saveNotificationSettings(NotificationSettingsEntity settings) async {}

  @override
  Future<StorageBreakdownEntity> getStorageBreakdown() async => const StorageBreakdownEntity(
        cacheBytes: 0,
        photosBytes: 0,
        databaseBytes: 0,
        pendingUploadsCount: 0,
        totalBytes: 0,
      );

  @override
  Future<int> clearTemporaryCache() async => 0;
}

void main() {
  setUp(() {
    final fakeRepository = _NoSessionAuthRepository();
    final fakeAccountLocalDataSource = _FakeAccountLocalDataSource();
    sl.registerLazySingleton<AccountLocalDataSource>(() => fakeAccountLocalDataSource);
    sl.registerLazySingleton<ThemeController>(
      () => ThemeController(localDataSource: fakeAccountLocalDataSource),
    );
    sl.registerLazySingleton<LanguageController>(
      () => LanguageController(localDataSource: fakeAccountLocalDataSource),
    );
    sl.registerLazySingleton<AuthRepository>(() => fakeRepository);
    sl.registerLazySingleton<AuthSessionManager>(
      () => AuthSessionManager(authRepository: fakeRepository),
    );
    sl.registerLazySingleton<GetCurrentSession>(
      () => GetCurrentSession(fakeRepository),
    );
    sl.registerLazySingleton<Login>(
      () => Login(fakeRepository, sl<AuthSessionManager>()),
    );
    sl.registerLazySingleton<NetworkInfo>(() => _FakeNetworkInfo());
    sl.registerLazySingleton<GetBiometricGreetingUser>(
      () => GetBiometricGreetingUser(fakeRepository),
    );
    sl.registerLazySingleton<RestoreBiometricSession>(
      () => RestoreBiometricSession(fakeRepository, sl<AuthSessionManager>()),
    );
    sl.registerLazySingleton<LoginWithGoogle>(
      () => LoginWithGoogle(fakeRepository, sl<AuthSessionManager>()),
    );
    sl.registerLazySingleton<LoginWithApple>(
      () => LoginWithApple(fakeRepository, sl<AuthSessionManager>()),
    );
    sl.registerLazySingleton<LoginWithFacebook>(
      () => LoginWithFacebook(fakeRepository, sl<AuthSessionManager>()),
    );
    sl.registerLazySingleton<OAuthSignInService>(
      () => _FakeOAuthSignInService(),
    );
    sl.registerLazySingleton<IsBiometricLoginEnabled>(
      () => IsBiometricLoginEnabled(fakeRepository),
    );
    sl.registerLazySingleton<BiometricAuthService>(
      () => BiometricAuthService(),
    );
  });

  tearDown(() => sl.reset());

  testWidgets('shows Login screen when no session is stored', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TulapApp());
    // WelcomePage has continuously-repeating animations (pulsing "Online"
    // dot, floating decorative icons), so `pumpAndSettle()` never
    // terminates here - pump a few fixed frames instead: one to flush the
    // WelcomeController's async `_load()` microtasks, one past the
    // one-shot entrance animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Masuk'), findsOneWidget);
  });
}
