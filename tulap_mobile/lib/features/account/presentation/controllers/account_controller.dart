import 'package:flutter/foundation.dart';
import '../../../../core/security/biometric_auth_service.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../../../../core/sync/background_sync_service.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/domain/usecases/disable_biometric_login.dart';
import '../../../auth/domain/usecases/enable_biometric_login.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../auth/domain/usecases/is_biometric_login_enabled.dart';
import '../../../auth/domain/usecases/logout.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../domain/entities/storage_breakdown_entity.dart';
import '../../domain/usecases/clear_app_cache.dart';
import '../../domain/usecases/get_storage_breakdown.dart';

class AccountState {
  final AuthUserEntity? user;
  final bool isLoggingOut;
  final bool biometricHardwareAvailable;
  final bool biometricLoginEnabled;
  final bool isTogglingBiometric;
  final int pendingSyncCount;
  final int failedSyncCount;
  final bool allSynced;
  final bool isSyncing;
  final StorageBreakdownEntity? storageBreakdown;
  final bool isClearingCache;
  final String? message;

  const AccountState({
    this.user,
    this.isLoggingOut = false,
    this.biometricHardwareAvailable = false,
    this.biometricLoginEnabled = false,
    this.isTogglingBiometric = false,
    this.pendingSyncCount = 0,
    this.failedSyncCount = 0,
    this.allSynced = true,
    this.isSyncing = false,
    this.storageBreakdown,
    this.isClearingCache = false,
    this.message,
  });

  String get syncStatusSubtitle {
    if (isSyncing) {
      return 'Sinkronisasi sedang berlangsung...';
    }
    if (failedSyncCount > 0) {
      return '$failedSyncCount data gagal terkirim (Ketuk untuk cek)';
    }
    if (pendingSyncCount > 0) {
      return '$pendingSyncCount data menunggu dikirim';
    }
    return '✓ Semua data tersinkronisasi';
  }

  AccountState copyWith({
    AuthUserEntity? user,
    bool? isLoggingOut,
    bool? biometricHardwareAvailable,
    bool? biometricLoginEnabled,
    bool? isTogglingBiometric,
    int? pendingSyncCount,
    int? failedSyncCount,
    bool? allSynced,
    bool? isSyncing,
    StorageBreakdownEntity? storageBreakdown,
    bool? isClearingCache,
    String? message,
  }) {
    return AccountState(
      user: user ?? this.user,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      biometricHardwareAvailable:
          biometricHardwareAvailable ?? this.biometricHardwareAvailable,
      biometricLoginEnabled:
          biometricLoginEnabled ?? this.biometricLoginEnabled,
      isTogglingBiometric: isTogglingBiometric ?? this.isTogglingBiometric,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      failedSyncCount: failedSyncCount ?? this.failedSyncCount,
      allSynced: allSynced ?? this.allSynced,
      isSyncing: isSyncing ?? this.isSyncing,
      storageBreakdown: storageBreakdown ?? this.storageBreakdown,
      isClearingCache: isClearingCache ?? this.isClearingCache,
      message: message,
    );
  }
}

class AccountController extends ChangeNotifier {
  final GetCurrentSession _getCurrentSession;
  final Logout _logout;
  final IsBiometricLoginEnabled _isBiometricLoginEnabled;
  final EnableBiometricLogin _enableBiometricLogin;
  final DisableBiometricLogin _disableBiometricLogin;
  final BiometricAuthService _biometricAuthService;
  final SyncQueueRepository _syncQueueRepository;
  final BackgroundSyncService _backgroundSyncService;
  final GetStorageBreakdown _getStorageBreakdown;
  final ClearAppCache _clearAppCache;
  final AuthSessionManager? _authSessionManager;

  AccountState _state = const AccountState();
  AccountState get state => _state;

  AccountController({
    required GetCurrentSession getCurrentSession,
    required Logout logout,
    required IsBiometricLoginEnabled isBiometricLoginEnabled,
    required EnableBiometricLogin enableBiometricLogin,
    required DisableBiometricLogin disableBiometricLogin,
    required BiometricAuthService biometricAuthService,
    required SyncQueueRepository syncQueueRepository,
    required BackgroundSyncService backgroundSyncService,
    required GetStorageBreakdown getStorageBreakdown,
    required ClearAppCache clearAppCache,
    AuthSessionManager? authSessionManager,
  }) : _getCurrentSession = getCurrentSession,
       _logout = logout,
       _isBiometricLoginEnabled = isBiometricLoginEnabled,
       _enableBiometricLogin = enableBiometricLogin,
       _disableBiometricLogin = disableBiometricLogin,
       _biometricAuthService = biometricAuthService,
       _syncQueueRepository = syncQueueRepository,
       _backgroundSyncService = backgroundSyncService,
       _getStorageBreakdown = getStorageBreakdown,
       _clearAppCache = clearAppCache,
       _authSessionManager = authSessionManager {
    _load();
    _backgroundSyncService.addListener(_onBackgroundSyncChanged);
    _authSessionManager?.addListener(_onUserSessionChanged);
  }

  void _onUserSessionChanged() {
    if (_isDisposed) return;
    final updatedUser = _authSessionManager?.currentUser;
    if (_state.user != updatedUser) {
      _update(_state.copyWith(user: updatedUser));
    }
  }

  void _onBackgroundSyncChanged() {
    _update(_state.copyWith(isSyncing: _backgroundSyncService.isSyncing));
    if (!_backgroundSyncService.isSyncing) {
      _loadSyncStatus();
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _authSessionManager?.removeListener(_onUserSessionChanged);
    _backgroundSyncService.removeListener(_onBackgroundSyncChanged);
    super.dispose();
  }

  void _update(AccountState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  Future<void> _load() async {
    final user = _authSessionManager?.currentUser ?? await _getCurrentSession();
    if (_authSessionManager != null && _authSessionManager.currentUser == null && user != null) {
      _authSessionManager.updateUser(user);
    }
    final hardwareAvailable = await _biometricAuthService.isAvailable();
    final biometricEnabled = await _isBiometricLoginEnabled();

    _update(
      _state.copyWith(
        user: user,
        biometricHardwareAvailable: hardwareAvailable,
        biometricLoginEnabled: biometricEnabled,
        isSyncing: _backgroundSyncService.isSyncing,
      ),
    );

    await _loadSyncStatus();
    await _loadStorageInfo();
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<void> _loadSyncStatus() async {
    final syncResult = await _syncQueueRepository.getAllRecords();
    syncResult.fold(
      (_) {},
      (records) {
        final pending = records.where((r) =>
            r.status == SyncStatus.pendingUpload ||
            r.status == SyncStatus.waitingForInternet ||
            r.status == SyncStatus.uploading).length;
        final failed = records.where((r) => r.status == SyncStatus.failed).length;
        final allSynced = records.every((r) => r.status == SyncStatus.synced);

        _update(
          _state.copyWith(
            pendingSyncCount: pending,
            failedSyncCount: failed,
            allSynced: allSynced,
          ),
        );
      },
    );
  }

  Future<void> _loadStorageInfo() async {
    try {
      final storage = await _getStorageBreakdown();
      _update(_state.copyWith(storageBreakdown: storage));
    } catch (_) {}
  }

  /// Mengaktifkan/menonaktifkan Masuk Cepat dengan Biometrik
  Future<void> toggleBiometricLogin(bool enable) async {
    _update(_state.copyWith(isTogglingBiometric: true));

    if (enable) {
      final verified = await _biometricAuthService.authenticate(
        'Verifikasi untuk mengaktifkan Masuk Cepat dengan Biometrik',
      );
      if (verified) {
        await _enableBiometricLogin();
      }
    } else {
      await _disableBiometricLogin();
    }

    final biometricEnabled = await _isBiometricLoginEnabled();
    _update(
      _state.copyWith(
        isTogglingBiometric: false,
        biometricLoginEnabled: biometricEnabled,
      ),
    );
  }

  /// Membersihkan cache aplikasi dengan aman tanpa menghapus database / foto bukti
  Future<void> clearCache() async {
    _update(_state.copyWith(isClearingCache: true));
    final result = await _clearAppCache();
    result.fold(
      (failure) {
        _update(
          _state.copyWith(
            isClearingCache: false,
            message: 'Gagal membersihkan cache: ${failure.message}',
          ),
        );
      },
      (bytes) {
        final formatted = StorageBreakdownEntity.formatBytes(bytes);
        _update(
          _state.copyWith(
            isClearingCache: false,
            message: 'Berhasil membersihkan $formatted cache sementara.',
          ),
        );
        _loadStorageInfo();
      },
    );
  }

  Future<void> signOut() async {
    _update(_state.copyWith(isLoggingOut: true));
    await _logout();
    _update(_state.copyWith(isLoggingOut: false));
  }
}
