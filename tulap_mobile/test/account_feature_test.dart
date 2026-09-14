import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/app/di/injection_container.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/core/sync/background_sync_service.dart';
import 'package:tulap_mobile/core/localization/app_language.dart';
import 'package:tulap_mobile/core/localization/language_controller.dart';
import 'package:tulap_mobile/core/theme/app_theme_mode.dart';
import 'package:tulap_mobile/features/account/data/datasources/account_local_datasource.dart';
import 'package:tulap_mobile/features/account/data/repositories/account_repository_impl.dart';
import 'package:tulap_mobile/features/account/domain/entities/account_settings_entity.dart';
import 'package:tulap_mobile/features/account/domain/entities/storage_breakdown_entity.dart';
import 'package:tulap_mobile/features/account/domain/repositories/account_repository.dart';
import 'package:tulap_mobile/features/account/domain/usecases/clear_app_cache.dart';
import 'package:tulap_mobile/features/account/domain/usecases/get_storage_breakdown.dart';
import 'package:tulap_mobile/features/account/presentation/controllers/account_controller.dart';
import 'package:tulap_mobile/features/account/presentation/pages/account_page.dart';
import 'package:tulap_mobile/features/account/presentation/pages/about_tulap_page.dart';
import 'package:tulap_mobile/features/account/presentation/pages/camera_settings_page.dart';
import 'package:tulap_mobile/features/account/presentation/pages/device_storage_page.dart';
import 'package:tulap_mobile/features/account/presentation/pages/display_settings_page.dart';
import 'package:tulap_mobile/features/account/presentation/pages/edit_profile_page.dart';
import 'package:tulap_mobile/features/account/presentation/pages/help_support_page.dart';
import 'package:tulap_mobile/features/account/presentation/pages/location_settings_page.dart';
import 'package:tulap_mobile/features/account/presentation/pages/notification_settings_page.dart';
import 'package:tulap_mobile/features/account/presentation/pages/privacy_page.dart';
import 'package:tulap_mobile/features/account/presentation/pages/profile_info_page.dart';
import 'package:tulap_mobile/features/account/presentation/pages/security_login_page.dart';
import 'package:tulap_mobile/features/account/presentation/pages/terms_page.dart';
import 'package:tulap_mobile/features/account/presentation/widgets/profile_header_card.dart';
import 'package:tulap_mobile/features/auth/data/models/auth_user_model.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/logout.dart';
import 'package:tulap_mobile/features/sync_queue/domain/entities/sync_record_entity.dart';
import 'package:tulap_mobile/features/sync_queue/domain/repositories/sync_queue_repository.dart';
import 'package:tulap_mobile/features/sync_queue/domain/usecases/process_sync_queue.dart';
import 'package:tulap_mobile/core/network/network_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

class _FakeDatabase extends Fake implements Database {
  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async => [];

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async => [{'count': 0}];
}

class _FakeNetworkInfo extends NetworkInfo {
  _FakeNetworkInfo() : super(Connectivity());

  @override
  Future<bool> get isConnected async => true;
}

class _MockAuthRepository implements AuthRepository {
  AuthUserEntity? currentUser = const AuthUserEntity(
    id: 'usr_mock_01',
    fullName: 'Leo Tiberius',
    email: 'leo@email.com',
    role: 'PEGAWAI',
    instansiName: 'BPKAD Kabupaten Mimika',
    nip: '198503152010011002',
    phoneNumber: '08123456789',
  );

  @override
  Future<AuthUserEntity?> getStoredUser() async => currentUser;

  @override
  Future<void> logout() async {
    currentUser = null;
  }

  @override
  Future<Either<Failure, AuthUserEntity>> login({
    required String email,
    required String password,
  }) async => Right(currentUser!);

  @override
  Future<Either<Failure, AuthUserEntity>> selfRegister({
    required String fullName,
    required String email,
    required String password,
    required String instansiName,
    String? phoneNumber,
  }) async => Right(currentUser!);

  @override
  Future<Either<Failure, String>> forgotPassword(String email) async =>
      const Right('OTP Terkirim');

  @override
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async => const Right('Kata sandi berhasil direset');

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithGoogle({
    required String idToken,
    String? email,
    String? displayName,
  }) async => Right(currentUser!);

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithApple({
    required String identityToken,
    String? fullName,
  }) async => Right(currentUser!);

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithFacebook({
    required String accessToken,
    String? email,
    String? fullName,
  }) async => Right(currentUser!);

  @override
  Future<Either<Failure, AuthUserEntity>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? instansiName,
    String? nip,
    String? photoUrl,
  }) async {
    currentUser = currentUser?.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
      instansiName: instansiName,
      nip: nip,
      photoUrl: photoUrl,
    );
    return Right(currentUser!);
  }

  @override
  Future<AuthUserEntity?> refreshStoredUserFromServer() async => currentUser;
}

class _MockSyncQueueRepository implements SyncQueueRepository {
  List<SyncRecordEntity> records = [];

  @override
  Future<Either<Failure, List<SyncRecordEntity>>> getAllRecords() async =>
      Right(records);

  @override
  Future<Either<Failure, SyncRecordEntity>> enqueue({
    required SyncEntityType entityType,
    required String entityLocalId,
    required String taskId,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, SyncRecordEntity>> processRecord(String recordId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> retryRecord(String recordId) async =>
      const Right(null);
}

class _MockAccountLocalDataSource implements AccountLocalDataSource {
  CameraSettingsEntity cameraSettings = const CameraSettingsEntity();
  NotificationSettingsEntity notificationSettings =
      const NotificationSettingsEntity();

  @override
  Future<CameraSettingsEntity> getCameraSettings() async => cameraSettings;

  @override
  Future<void> saveCameraSettings(CameraSettingsEntity settings) async {
    cameraSettings = settings;
  }

  @override
  Future<NotificationSettingsEntity> getNotificationSettings() async =>
      notificationSettings;

  @override
  Future<void> saveNotificationSettings(
    NotificationSettingsEntity settings,
  ) async {
    notificationSettings = settings;
  }

  AppThemeMode themeMode = AppThemeMode.system;

  @override
  Future<AppThemeMode> getThemeMode() async => themeMode;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    themeMode = mode;
  }

  AppLanguage language = AppLanguage.id;

  @override
  Future<AppLanguage> getLanguage() async => language;

  @override
  Future<void> saveLanguage(AppLanguage lang) async {
    language = lang;
  }

  @override
  Future<StorageBreakdownEntity> getStorageBreakdown() async {
    return const StorageBreakdownEntity(
      databaseBytes: 1024 * 500, // 500 KB
      photosBytes: 1024 * 1024 * 12, // 12 MB
      cacheBytes: 1024 * 1024 * 2, // 2 MB
      pendingUploadsCount: 0,
      totalBytes: (1024 * 500) + (1024 * 1024 * 14),
    );
  }

  @override
  Future<int> clearTemporaryCache() async {
    return 1024 * 1024 * 2; // 2 MB cleared
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository mockAuthRepo;
  late _MockSyncQueueRepository mockSyncRepo;
  late _MockAccountLocalDataSource mockAccountLocal;
  late AccountRepository accountRepo;
  late BackgroundSyncService backgroundSync;

  setUpAll(() async {
    mockAuthRepo = _MockAuthRepository();
    mockSyncRepo = _MockSyncQueueRepository();
    mockAccountLocal = _MockAccountLocalDataSource();
    accountRepo = AccountRepositoryImpl(localDataSource: mockAccountLocal);

    final netInfo = _FakeNetworkInfo();
    final processQueue = ProcessSyncQueue(
      repository: mockSyncRepo,
      networkInfo: netInfo,
    );
    backgroundSync = BackgroundSyncService(
      processSyncQueue: processQueue,
      networkInfo: netInfo,
    );

    // Initialize clean GetIt for testing
    await initDependencies(database: _FakeDatabase());

    // Override with test mocks
    if (sl.isRegistered<AuthRepository>()) sl.unregister<AuthRepository>();
    sl.registerSingleton<AuthRepository>(mockAuthRepo);

    if (sl.isRegistered<SyncQueueRepository>()) sl.unregister<SyncQueueRepository>();
    sl.registerSingleton<SyncQueueRepository>(mockSyncRepo);

    if (sl.isRegistered<AccountRepository>()) sl.unregister<AccountRepository>();
    sl.registerSingleton<AccountRepository>(accountRepo);

    if (sl.isRegistered<LanguageController>()) sl.unregister<LanguageController>();
    sl.registerSingleton<LanguageController>(LanguageController(localDataSource: mockAccountLocal));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (MethodCall call) async {
        if (call.method == 'isLocationServiceEnabled') return true;
        if (call.method == 'checkPermission') return 1; // whileInUse
        return null;
      },
    );
  });

  group('Account Entities & Models Unit Tests', () {
    test('ProfileHeaderCard.getInitials generates correct initials', () {
      expect(ProfileHeaderCard.getInitials('Leo Tiberius'), equals('LT'));
      expect(ProfileHeaderCard.getInitials('Mohamed Ali'), equals('MA'));
      expect(ProfileHeaderCard.getInitials('Leonardo'), equals('LE'));
      expect(ProfileHeaderCard.getInitials(''), equals('U'));
    });

    test('StorageBreakdownEntity.formatBytes formats correctly', () {
      expect(StorageBreakdownEntity.formatBytes(500), equals('500 B'));
      expect(StorageBreakdownEntity.formatBytes(1024 * 50), equals('50.0 KB'));
      expect(StorageBreakdownEntity.formatBytes(1024 * 1024 * 12), equals('12.0 MB'));
      expect(
        StorageBreakdownEntity.formatBytes(1024 * 1024 * 1024 * 2),
        equals('2.00 GB'),
      );
    });

    test('CameraSettingsEntity serializes to and from JSON', () {
      const original = CameraSettingsEntity(
        showAddress: true,
        showCoordinates: false,
        showQrCode: true,
        saveWatermarkedCopy: true,
      );
      final json = original.toJson();
      final restored = CameraSettingsEntity.fromJson(json);

      expect(restored.showAddress, isTrue);
      expect(restored.showCoordinates, isFalse);
      expect(restored.showQrCode, isTrue);
      expect(restored.saveWatermarkedCopy, isTrue);
    });

    test('NotificationSettingsEntity serializes to and from JSON', () {
      const original = NotificationSettingsEntity(
        taskAlerts: true,
        syncStatusAlerts: false,
        activityReminders: true,
        systemAnnouncements: false,
      );
      final json = original.toJson();
      final restored = NotificationSettingsEntity.fromJson(json);

      expect(restored.taskAlerts, isTrue);
      expect(restored.syncStatusAlerts, isFalse);
      expect(restored.activityReminders, isTrue);
      expect(restored.systemAnnouncements, isFalse);
    });

    test('AuthUserModel stores and parses extended fields', () {
      final user = AuthUserModel(
        id: 'usr_001',
        fullName: 'Budi Santoso',
        email: 'budi@tulap.id',
        role: 'PEGAWAI',
        instansiName: 'Dinas PU',
        nip: '19900101',
        phoneNumber: '0812345678',
        photoUrl: 'https://tulap.id/photo.jpg',
        authProvider: 'google',
      );

      final map = user.toStorageMap();
      final restored = AuthUserModel.fromStorageMap(map);

      expect(restored.id, equals('usr_001'));
      expect(restored.fullName, equals('Budi Santoso'));
      expect(restored.phoneNumber, equals('0812345678'));
      expect(restored.photoUrl, equals('https://tulap.id/photo.jpg'));
      expect(restored.authProvider, equals('google'));

      final modified = user.copyWith(photoUrl: '/local/app_docs/photo.jpg');
      expect(modified.photoUrl, equals('/local/app_docs/photo.jpg'));
      expect(modified.fullName, equals('Budi Santoso'));
    });
  });

  group('AccountController Unit Tests', () {
    test('Loads authenticated user and storage statistics cleanly', () async {
      final controller = AccountController(
        getCurrentSession: GetCurrentSession(mockAuthRepo),
        logout: Logout(mockAuthRepo),
        syncQueueRepository: mockSyncRepo,
        backgroundSyncService: backgroundSync,
        getStorageBreakdown: GetStorageBreakdown(accountRepo),
        clearAppCache: ClearAppCache(accountRepo),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state.user, isNotNull);
      expect(controller.state.user?.fullName, equals('Leo Tiberius'));
      expect(controller.state.allSynced, isTrue);
      expect(controller.state.syncStatusSubtitle, contains('Semua data tersinkronisasi'));
      expect(controller.state.storageBreakdown, isNotNull);

      controller.dispose();
    });

    test('Clears cache safely without error', () async {
      final controller = AccountController(
        getCurrentSession: GetCurrentSession(mockAuthRepo),
        logout: Logout(mockAuthRepo),
        syncQueueRepository: mockSyncRepo,
        backgroundSyncService: backgroundSync,
        getStorageBreakdown: GetStorageBreakdown(accountRepo),
        clearAppCache: ClearAppCache(accountRepo),
      );

      await controller.clearCache();
      expect(controller.state.isClearingCache, isFalse);
      expect(controller.state.message, contains('Berhasil membersihkan'));

      controller.dispose();
    });
  });

  group('Account Page & Sub-Pages Widget Tests', () {
    testWidgets('AccountPage renders Profile Header, 4 Sections, and Logout button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AccountPage(),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Check Title & Header
      expect(find.text('Akun'), findsWidgets);
      expect(find.text('Leo Tiberius'), findsOneWidget);
      expect(find.text('leo@email.com'), findsOneWidget);
      expect(find.text('BPKAD Kabupaten Mimika'), findsOneWidget);
      expect(find.text('Edit Profil'), findsOneWidget);

      // 2. Check 4 Section Titles
      expect(find.text('AKUN & KEAMANAN'), findsOneWidget);
      expect(find.text('DATA & SINKRONISASI'), findsOneWidget);
      expect(find.text('PENGATURAN'), findsOneWidget);
      expect(find.text('BANTUAN & INFORMASI'), findsOneWidget);

      // 3. Check Rows
      expect(find.text('Informasi Profil'), findsOneWidget);
      expect(find.text('Keamanan & Login'), findsOneWidget);
      expect(find.text('Status Sinkronisasi'), findsOneWidget);
      expect(find.text('Penyimpanan Perangkat'), findsOneWidget);
      expect(find.text('Data & Cache'), findsOneWidget);
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Kamera & Dokumentasi'), findsOneWidget);
      expect(find.text('Lokasi & GPS'), findsOneWidget);
      expect(find.text('Tampilan'), findsOneWidget);
      expect(find.text('Bantuan & Dukungan'), findsOneWidget);
      expect(find.text('Kebijakan Privasi'), findsOneWidget);
      expect(find.text('Syarat Penggunaan'), findsOneWidget);
      expect(find.text('Tentang Tulap.id'), findsOneWidget);

      // 4. Check Logout Button
      expect(find.text('Keluar dari Akun'), findsOneWidget);
    });

    testWidgets('EditProfilePage renders form and saves changes', (tester) async {
      final user = mockAuthRepo.currentUser!;

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfilePage(user: user),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);

      // Change name
      final nameField = find.widgetWithText(TextFormField, 'Leo Tiberius');
      await tester.enterText(nameField, 'Leonardo Da Vinci');
      await tester.pump();

      // Tap Simpan
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(mockAuthRepo.currentUser?.fullName, equals('Leonardo Da Vinci'));
    });

    testWidgets('ProfileInfoPage renders properly', (tester) async {
      final user = mockAuthRepo.currentUser!;
      await tester.pumpWidget(MaterialApp(home: ProfileInfoPage(user: user)));
      await tester.pumpAndSettle();
      expect(find.text('Informasi Profil'), findsOneWidget);
      expect(find.text('Leonardo Da Vinci'), findsOneWidget);
    });

    testWidgets('SecurityLoginPage renders properly', (tester) async {
      final user = mockAuthRepo.currentUser!;
      await tester.pumpWidget(MaterialApp(home: SecurityLoginPage(user: user)));
      await tester.pumpAndSettle();
      expect(find.text('Keamanan & Login'), findsOneWidget);
    });

    testWidgets('DeviceStoragePage renders properly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeviceStoragePage()));
      await tester.pumpAndSettle();
      expect(find.text('Penyimpanan Perangkat'), findsOneWidget);
    });

    testWidgets('CameraSettingsPage renders properly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CameraSettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Kamera & Dokumentasi'), findsOneWidget);
    });

    testWidgets('LocationSettingsPage renders properly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LocationSettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Lokasi & GPS'), findsOneWidget);
    });

    testWidgets('NotificationSettingsPage renders properly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: NotificationSettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Notifikasi'), findsOneWidget);
    });

    testWidgets('DisplaySettingsPage renders properly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DisplaySettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Tampilan'), findsOneWidget);
    });

    testWidgets('HelpSupportPage renders properly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HelpSupportPage()));
      await tester.pumpAndSettle();
      expect(find.text('Bantuan & Dukungan'), findsOneWidget);
    });

    testWidgets('PrivacyPage renders properly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PrivacyPage()));
      await tester.pumpAndSettle();
      expect(find.text('Kebijakan Privasi'), findsOneWidget);
    });

    testWidgets('TermsPage renders properly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TermsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Syarat Penggunaan'), findsOneWidget);
    });

    testWidgets('AboutTulapPage renders properly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AboutTulapPage()));
      await tester.pumpAndSettle();
      expect(find.text('Tentang Tulap.id'), findsOneWidget);
    });
  });

  group('Account Module Multi-Viewport Responsive Tests', () {
    final viewports = [
      const Size(320, 568), // iPhone SE 1st gen / Small Android
      const Size(360, 640), // Standard Android
      const Size(375, 812), // iPhone X/11/12 mini
      const Size(390, 844), // iPhone 12/13/14
      const Size(412, 915), // Google Pixel / Galaxy
      const Size(430, 932), // iPhone Pro Max / Large phone
    ];

    for (final size in viewports) {
      testWidgets('AccountPage renders cleanly on viewport ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: AccountPage(),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Akun'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('AccountPage handles large text scale factor (1.5x) without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(
            home: AccountPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
