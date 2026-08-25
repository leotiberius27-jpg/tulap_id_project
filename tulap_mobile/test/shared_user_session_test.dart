import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tulap_mobile/core/network/network_info.dart';
import 'package:tulap_mobile/core/session/auth_session_manager.dart';
import 'package:tulap_mobile/core/sync/background_sync_service.dart';
import 'package:tulap_mobile/core/widgets/user_avatar.dart';
import 'package:tulap_mobile/features/account/presentation/controllers/account_controller.dart';
import 'package:tulap_mobile/features/account/presentation/widgets/profile_header_card.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/disable_biometric_login.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/enable_biometric_login.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/is_biometric_login_enabled.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/logout.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/update_user_profile.dart';
import 'package:tulap_mobile/features/home/presentation/controllers/home_controller.dart';
import 'package:tulap_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:tulap_mobile/features/sync_queue/domain/repositories/sync_queue_repository.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_active_tasks.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_task_detail.dart';
import 'package:tulap_mobile/features/account/domain/usecases/clear_app_cache.dart';
import 'package:tulap_mobile/features/account/domain/usecases/get_storage_breakdown.dart';
import 'package:tulap_mobile/core/security/biometric_auth_service.dart';

import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/features/sync_queue/domain/entities/sync_record_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';

class _FakeAuthRepo extends Fake implements AuthRepository {
  AuthUserEntity? storedUser = const AuthUserEntity(
    id: 'usr_001',
    fullName: 'Leo Tiberius',
    email: 'leo@tulap.id',
    role: 'PEGAWAI',
    instansiName: 'BPKAD Kabupaten Mimika',
  );

  @override
  Future<AuthUserEntity?> getStoredUser() async => storedUser;

  @override
  Future<Either<Failure, AuthUserEntity>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? instansiName,
    String? nip,
    String? photoUrl,
  }) async {
    storedUser = storedUser?.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
      instansiName: instansiName,
      nip: nip,
      photoUrl: photoUrl,
    );
    return Right(storedUser!);
  }

  @override
  Future<void> logout() async {
    storedUser = null;
  }
}

class _FakeNetworkInfo extends Fake implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

class _FakeSyncQueueRepo extends Fake implements SyncQueueRepository {
  @override
  Future<Either<Failure, List<SyncRecordEntity>>> getAllRecords() async =>
      const Right(<SyncRecordEntity>[]);
}

class _FakeGetActiveTasks extends Fake implements GetActiveTasks {
  @override
  Future<Either<Failure, List<TaskEntity>>> call() async =>
      const Right(<TaskEntity>[]);
}

class _FakeGetTaskDetail extends Fake implements GetTaskDetail {}

class _FakeBackgroundSyncService extends Fake implements BackgroundSyncService {
  @override
  bool get isSyncing => false;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class _FakeBiometricAuthService extends Fake implements BiometricAuthService {
  @override
  Future<bool> isAvailable() async => false;
}

class _FakeIsBiometricLoginEnabled extends Fake implements IsBiometricLoginEnabled {
  @override
  Future<bool> call() async => false;
}

class _FakeEnableBiometricLogin extends Fake implements EnableBiometricLogin {}
class _FakeDisableBiometricLogin extends Fake implements DisableBiometricLogin {}
class _FakeGetStorageBreakdown extends Fake implements GetStorageBreakdown {}
class _FakeClearAppCache extends Fake implements ClearAppCache {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthUserEntity Value Equality & Immutability', () {
    test('Entities with same fields are equal and have identical hashCodes', () {
      const user1 = AuthUserEntity(
        id: 'usr_001',
        fullName: 'Leo Tiberius',
        email: 'leo@tulap.id',
        role: 'PEGAWAI',
        photoUrl: '/path/to/photo.jpg',
      );

      const user2 = AuthUserEntity(
        id: 'usr_001',
        fullName: 'Leo Tiberius',
        email: 'leo@tulap.id',
        role: 'PEGAWAI',
        photoUrl: '/path/to/photo.jpg',
      );

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('Entities with different photoUrl are NOT equal', () {
      const user1 = AuthUserEntity(
        id: 'usr_001',
        fullName: 'Leo Tiberius',
        email: 'leo@tulap.id',
        role: 'PEGAWAI',
        photoUrl: '/path/to/photo1.jpg',
      );

      const user2 = AuthUserEntity(
        id: 'usr_001',
        fullName: 'Leo Tiberius',
        email: 'leo@tulap.id',
        role: 'PEGAWAI',
        photoUrl: '/path/to/photo2.jpg',
      );

      expect(user1, isNot(equals(user2)));
      expect(user1.hashCode, isNot(equals(user2.hashCode)));
    });
  });

  group('UserAvatar Widget Unit & Rendering Tests', () {
    test('computeInitials produces correct 2-letter fallback initials', () {
      expect(UserAvatar.computeInitials('Leo Tiberius'), equals('LT'));
      expect(UserAvatar.computeInitials('Mohamed Ali'), equals('MA'));
      expect(UserAvatar.computeInitials('Leonardo'), equals('LE'));
      expect(UserAvatar.computeInitials('   '), equals('U'));
      expect(UserAvatar.computeInitials('A'), equals('A'));
    });

    testWidgets('Renders initials when photoUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              fullName: 'Leo Tiberius',
              photoUrl: null,
              size: 42,
            ),
          ),
        ),
      );

      expect(find.text('LT'), findsOneWidget);
    });

    testWidgets('HomeHeader renders UserAvatar with initials fallback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              fullName: 'Leo Tiberius',
              agencyName: 'BPKAD Mimika',
              avatarUrl: null,
              unreadNotificationCount: 0,
              onNotificationTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('LT'), findsOneWidget);
      expect(find.text('Leo Tiberius'), findsOneWidget);
    });
  });

  group('Shared Reactive User State Across Layers (Single Source of Truth)', () {
    late _FakeAuthRepo fakeAuthRepo;
    late AuthSessionManager sessionManager;
    late UpdateUserProfile updateUserProfile;
    late HomeController homeController;
    late AccountController accountController;

    setUp(() async {
      fakeAuthRepo = _FakeAuthRepo();
      sessionManager = AuthSessionManager(authRepository: fakeAuthRepo);
      updateUserProfile = UpdateUserProfile(fakeAuthRepo, sessionManager);

      await sessionManager.loadInitialSession();

      homeController = HomeController(
        getCurrentSession: GetCurrentSession(fakeAuthRepo),
        getActiveTasks: _FakeGetActiveTasks() as dynamic,
        getTaskDetail: _FakeGetTaskDetail() as dynamic,
        syncQueueRepository: _FakeSyncQueueRepo(),
        networkInfo: _FakeNetworkInfo(),
        backgroundSyncService: _FakeBackgroundSyncService(),
        authSessionManager: sessionManager,
      );

      accountController = AccountController(
        getCurrentSession: GetCurrentSession(fakeAuthRepo),
        logout: Logout(fakeAuthRepo, sessionManager),
        isBiometricLoginEnabled: _FakeIsBiometricLoginEnabled(),
        enableBiometricLogin: _FakeEnableBiometricLogin(),
        disableBiometricLogin: _FakeDisableBiometricLogin(),
        biometricAuthService: _FakeBiometricAuthService(),
        syncQueueRepository: _FakeSyncQueueRepo(),
        backgroundSyncService: _FakeBackgroundSyncService(),
        getStorageBreakdown: _FakeGetStorageBreakdown(),
        clearAppCache: _FakeClearAppCache(),
        authSessionManager: sessionManager,
      );
    });

    tearDown(() {
      homeController.dispose();
      accountController.dispose();
    });

    test('Updating profile photo reactively updates HomeController and AccountController', () async {
      // 1. Initial State has no photo
      expect(sessionManager.currentUser?.photoUrl, isNull);
      expect(homeController.state.user?.photoUrl, isNull);
      expect(accountController.state.user?.photoUrl, isNull);

      // 2. User updates profile photo via UpdateUserProfile
      const newPhotoPath = '/data/user/0/id.tulap.mobile/cache/profile_123.jpg';
      final result = await updateUserProfile(
        fullName: 'Leo Tiberius Updated',
        photoUrl: newPhotoPath,
      );

      expect(result.isRight(), isTrue);

      // 3. Verify AuthSessionManager has the new photo
      expect(sessionManager.currentUser?.fullName, equals('Leo Tiberius Updated'));
      expect(sessionManager.currentUser?.photoUrl, equals(newPhotoPath));

      // 4. Verify HomeController reactively received the updated user without page reload
      expect(homeController.state.user?.fullName, equals('Leo Tiberius Updated'));
      expect(homeController.state.user?.photoUrl, equals(newPhotoPath));

      // 5. Verify AccountController reactively received the updated user
      expect(accountController.state.user?.fullName, equals('Leo Tiberius Updated'));
      expect(accountController.state.user?.photoUrl, equals(newPhotoPath));
    });

    testWidgets('Mounted Home and Account widgets rebuild automatically on session update', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Mounted Home Header
                ListenableBuilder(
                  listenable: homeController,
                  builder: (context, _) {
                    return HomeHeader(
                      fullName: homeController.state.user?.fullName ?? 'Leo Tiberius',
                      agencyName: 'BPKAD Mimika',
                      avatarUrl: homeController.state.user?.photoUrl,
                      unreadNotificationCount: 0,
                      onNotificationTap: () {},
                    );
                  },
                ),
                // Mounted Account Profile Card
                ListenableBuilder(
                  listenable: accountController,
                  builder: (context, _) {
                    final u = accountController.state.user ?? const AuthUserEntity(
                      id: '0',
                      fullName: 'Leo Tiberius',
                      email: 'leo@tulap.id',
                      role: 'PEGAWAI',
                    );
                    return ProfileHeaderCard(
                      user: u,
                      onEditProfile: () {},
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Initially shows fallback initials 'LT'
      expect(find.text('LT'), findsNWidgets(2));

      // User updates their name and photo
      await updateUserProfile(
        fullName: 'Ahmad Fauzi',
        photoUrl: null,
      );

      await tester.pump();

      // Both HomeHeader and ProfileHeaderCard automatically rebuilt with 'AF' initials
      expect(find.text('AF'), findsNWidgets(2));
      expect(find.text('Ahmad Fauzi'), findsNWidgets(2));
    });
  });
}
