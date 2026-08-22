// Smoke test: app should boot to the Login screen when no session is
// stored, without needing the real database/secure-storage plugins.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tulap_mobile/app/di/injection_container.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/core/network/network_info.dart';
import 'package:tulap_mobile/core/security/biometric_auth_service.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_biometric_greeting_user.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/restore_biometric_session.dart';
import 'package:tulap_mobile/main.dart';

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
  Future<Either<Failure, AuthUserEntity>> loginWithGoogle(String idToken) {
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
  Future<bool> isBiometricLoginEnabled() async => false;

  @override
  Future<void> enableBiometricLogin() async {}

  @override
  Future<void> disableBiometricLogin() async {}

  @override
  Future<AuthUserEntity?> getBiometricGreetingUser() async => null;

  @override
  Future<AuthUserEntity?> restoreBiometricSession() async => null;
}

void main() {
  setUp(() {
    final fakeRepository = _NoSessionAuthRepository();
    sl.registerLazySingleton<GetCurrentSession>(
      () => GetCurrentSession(fakeRepository),
    );
    sl.registerLazySingleton<Login>(() => Login(fakeRepository));
    sl.registerLazySingleton<NetworkInfo>(() => _FakeNetworkInfo());
    sl.registerLazySingleton<GetBiometricGreetingUser>(
      () => GetBiometricGreetingUser(fakeRepository),
    );
    sl.registerLazySingleton<RestoreBiometricSession>(
      () => RestoreBiometricSession(fakeRepository),
    );
    sl.registerLazySingleton<BiometricAuthService>(() => BiometricAuthService());
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
