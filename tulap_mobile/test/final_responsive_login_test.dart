import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/core/security/biometric_auth_service.dart';
import 'package:tulap_mobile/core/security/oauth_sign_in_service.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/is_biometric_login_enabled.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login_with_apple.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login_with_facebook.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login_with_google.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/restore_biometric_session.dart';
import 'package:tulap_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/repositories/task_repository.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_active_tasks.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/pick_active_task.dart';

class _FakeBiometricAuthService implements BiometricAuthService {
  bool available = true;
  bool shouldSucceed = true;
  int authenticateCallCount = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    authenticateCallCount++;
    return shouldSucceed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  bool failNextLogin = false;
  bool biometricEnabled = false;
  String? lastLoginEmail;
  String? lastLoginPassword;

  @override
  Future<Either<Failure, AuthUserEntity>> login({
    required String email,
    required String password,
  }) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
    if (failNextLogin) {
      return const Left(AuthFailure('Email atau password tidak sesuai.'));
    }
    return const Right(
      AuthUserEntity(
        id: 'usr-1',
        fullName: 'Budi Santoso',
        email: 'budi@tulap.id',
        role: 'PEGAWAI',
        nip: '198501012010011001',
        instansiName: 'Dinas Lingkungan Hidup',
      ),
    );
  }

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithGoogle({
    required String idToken,
    String? email,
    String? displayName,
  }) async {
    return const Right(
      AuthUserEntity(
        id: 'usr-google',
        fullName: 'Leonardo',
        email: 'google@tulap.id',
        role: 'PEGAWAI',
      ),
    );
  }

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithApple({
    required String identityToken,
    String? fullName,
  }) async {
    return const Right(
      AuthUserEntity(
        id: 'usr-apple',
        fullName: 'Leonardo',
        email: 'apple@tulap.id',
        role: 'PEGAWAI',
      ),
    );
  }

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithFacebook({
    required String accessToken,
    String? email,
    String? fullName,
  }) async {
    return const Right(
      AuthUserEntity(
        id: 'usr-facebook',
        fullName: 'Leonardo',
        email: 'facebook@tulap.id',
        role: 'PEGAWAI',
      ),
    );
  }

  @override
  Future<AuthUserEntity?> getCurrentSession() async => null;

  @override
  Future<bool> isBiometricLoginEnabled() async => biometricEnabled;

  @override
  Future<AuthUserEntity?> restoreBiometricSession() async => const AuthUserEntity(
        id: 'usr-biometric',
        fullName: 'Leonardo',
        email: 'leo@tulap.id',
        role: 'PEGAWAI',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOAuthService implements OAuthSignInService {
  @override
  Future<({String idToken, String? email, String? displayName})?>
  signInWithGoogle() async {
    return (
      idToken: 'mock-google-token',
      email: 'google@tulap.id',
      displayName: 'Leonardo',
    );
  }

  @override
  Future<({String identityToken, String? fullName})?> signInWithApple() async {
    return (identityToken: 'mock-apple-token', fullName: 'Leonardo');
  }

  @override
  Future<({String accessToken, String? email, String? displayName})?>
  signInWithFacebook() async {
    return (
      accessToken: 'mock-facebook-token',
      email: 'facebook@tulap.id',
      displayName: 'Leonardo',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTaskRepository implements TaskRepository {
  @override
  Future<Either<Failure, List<TaskEntity>>> getActiveTasks() async =>
      const Right([]);
  @override
  Future<Either<Failure, TaskEntity?>> pickActiveTask() async =>
      const Right(null);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeAuthRepository fakeRepo;
  late _FakeOAuthService fakeOAuth;
  late _FakeTaskRepository fakeTaskRepo;
  late _FakeBiometricAuthService fakeBiometric;

  setUp(() {
    fakeRepo = _FakeAuthRepository();
    fakeOAuth = _FakeOAuthService();
    fakeTaskRepo = _FakeTaskRepository();
    fakeBiometric = _FakeBiometricAuthService();
    final sl = GetIt.instance;
    sl.reset();

    sl.registerLazySingleton<Login>(() => Login(fakeRepo));
    sl.registerLazySingleton<LoginWithGoogle>(() => LoginWithGoogle(fakeRepo));
    sl.registerLazySingleton<LoginWithApple>(() => LoginWithApple(fakeRepo));
    sl.registerLazySingleton<LoginWithFacebook>(() => LoginWithFacebook(fakeRepo));
    sl.registerLazySingleton<OAuthSignInService>(() => fakeOAuth);
    sl.registerLazySingleton<BiometricAuthService>(() => fakeBiometric);
    sl.registerLazySingleton<IsBiometricLoginEnabled>(
      () => IsBiometricLoginEnabled(fakeRepo),
    );
    sl.registerLazySingleton<RestoreBiometricSession>(
      () => RestoreBiometricSession(fakeRepo),
    );
    sl.registerLazySingleton<GetCurrentSession>(
      () => GetCurrentSession(fakeRepo),
    );
    sl.registerLazySingleton<GetActiveTasks>(
      () => GetActiveTasks(fakeTaskRepo),
    );
    sl.registerLazySingleton<PickActiveTask>(
      () => PickActiveTask(sl<GetActiveTasks>()),
    );
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget buildLoginPage({ValueChanged<AuthUserEntity>? onSuccess}) {
    return MaterialApp(
      initialRoute: '/home',
      routes: {
        '/home': (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              child: const Text('Open Login'),
            ),
          ),
        ),
        '/login': (context) => LoginPage(onLoginSuccess: onSuccess ?? (_) {}),
      },
    );
  }

  Future<void> openLoginPage(
    WidgetTester tester, {
    ValueChanged<AuthUserEntity>? onSuccess,
  }) async {
    await tester.pumpWidget(buildLoginPage(onSuccess: onSuccess));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Login'));
    await tester.pumpAndSettle();
  }

  group('Final LoginPage Responsive Rendering Tests', () {
    const viewports = [
      Size(320, 568), // iPhone SE 1st gen / Narrow Android
      Size(360, 640), // Standard Compact Android
      Size(375, 812), // iPhone X / 11 Pro
      Size(390, 844), // iPhone 12 / 13 / 14 / Realme
      Size(412, 915), // Pixel 7
      Size(430, 932), // iPhone Pro Max / Ultra
    ];

    for (final size in viewports) {
      testWidgets(
        'Renders cleanly on viewport ${size.width}x${size.height} without overflows',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await openLoginPage(tester);

          expect(find.text('Selamat Datang'), findsOneWidget);
          expect(
            find.text('Masuk untuk melanjutkan ke Tulap.id'),
            findsOneWidget,
          );
          expect(find.text('Email'), findsOneWidget);
          expect(find.text('Password'), findsOneWidget);
          expect(find.text('Masuk'), findsOneWidget);
          expect(find.text('Lupa password?'), findsOneWidget);
          expect(find.text('Masuk dengan Google'), findsOneWidget);
          expect(find.text('Daftar'), findsOneWidget);

          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Form Validation & Submission Tests', () {
    testWidgets('Validates empty email and password inputs', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await openLoginPage(tester);

      // Tap Masuk without filling fields
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);
    });

    testWidgets('Validates invalid email format', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await openLoginPage(tester);

      final emailField = find.widgetWithText(TextFormField, 'nama@email.com');
      final passwordField = find.widgetWithText(TextFormField, '••••••••');

      await tester.enterText(emailField, 'invalid-email-format');
      await tester.enterText(passwordField, 'secret123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Format email tidak valid'), findsOneWidget);
    });

    testWidgets('Password visibility toggle toggles obscureText', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await openLoginPage(tester);

      final toggleFinder = find.byTooltip('Tampilkan password');
      expect(toggleFinder, findsOneWidget);

      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Sembunyikan password'), findsOneWidget);
    });

    testWidgets(
      'Submits valid credentials successfully and triggers callback',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        AuthUserEntity? loggedInUser;
        await openLoginPage(tester, onSuccess: (user) => loggedInUser = user);

        final emailField = find.widgetWithText(TextFormField, 'nama@email.com');
        final passwordField = find.widgetWithText(TextFormField, '••••••••');

        await tester.enterText(emailField, 'budi@tulap.id');
        await tester.enterText(passwordField, 'secret123');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        expect(fakeRepo.lastLoginEmail, 'budi@tulap.id');
        expect(fakeRepo.lastLoginPassword, 'secret123');
        expect(loggedInUser?.id, 'usr-1');
      },
    );

    testWidgets('Displays user-friendly error message on login failure', (
      tester,
    ) async {
      fakeRepo.failNextLogin = true;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await openLoginPage(tester);

      final emailField = find.widgetWithText(TextFormField, 'nama@email.com');
      final passwordField = find.widgetWithText(TextFormField, '••••••••');

      await tester.enterText(emailField, 'wrong@tulap.id');
      await tester.enterText(passwordField, 'wrongpass');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Email atau password tidak sesuai.'), findsOneWidget);
    });

    testWidgets('Triggers Google Sign-In on tap', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      AuthUserEntity? loggedInUser;
      await openLoginPage(tester, onSuccess: (user) => loggedInUser = user);

      await tester.tap(find.text('Masuk dengan Google'));
      await tester.pumpAndSettle();

      expect(loggedInUser?.id, 'usr-google');
    });

    testWidgets('Fingerprint biometric is tested first and fails if fingerprint does not match', (tester) async {
      fakeRepo.biometricEnabled = true;
      fakeBiometric.shouldSucceed = false; // Fingerprint test fails / does not match

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      AuthUserEntity? loggedInUser;
      await openLoginPage(tester, onSuccess: (user) => loggedInUser = user);

      final biometricBtn = find.widgetWithText(OutlinedButton, 'Masuk dengan Biometrik');
      expect(biometricBtn, findsOneWidget);

      await tester.tap(biometricBtn);
      await tester.pumpAndSettle();

      expect(fakeBiometric.authenticateCallCount, 1);
      expect(loggedInUser, isNull);
      expect(find.text('Sidik jari tidak cocok atau verifikasi dibatalkan.'), findsOneWidget);
    });

    testWidgets('Fingerprint biometric is tested first and logs in only when matching', (tester) async {
      fakeRepo.biometricEnabled = true;
      fakeBiometric.shouldSucceed = true; // Fingerprint test succeeds / matches

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      AuthUserEntity? loggedInUser;
      await openLoginPage(tester, onSuccess: (user) => loggedInUser = user);

      final biometricBtn = find.widgetWithText(OutlinedButton, 'Masuk dengan Biometrik');
      expect(biometricBtn, findsOneWidget);

      await tester.tap(biometricBtn);
      await tester.pumpAndSettle();

      expect(fakeBiometric.authenticateCallCount, 1);
      expect(loggedInUser?.id, 'usr-biometric');
    });
  });
}
