import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../../features/auth/domain/entities/auth_user_entity.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// AuthSessionManager
/// ----------------------------------------------------------------------
/// Single Source of Truth untuk state pengguna terautentikasi.
/// Seluruh layar (HomeHeader, HomePage, AccountPage, EditProfilePage,
/// MainShell) berlangganan ke state terpusat ini sehingga pembaruan profil
/// (foto, nama, instansi, dll.) langsung terefleksi secara reaktif tanpa
/// memerlukan restart aplikasi atau navigasi paksa.
/// ----------------------------------------------------------------------
class AuthSessionManager extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthUserEntity? _currentUser;
  bool _isLoading = false;

  AuthSessionManager({required AuthRepository authRepository})
      : _authRepository = authRepository;

  AuthUserEntity? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  /// Memuat sesi awal dari penyimpanan persisten lokal
  Future<AuthUserEntity?> loadInitialSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authRepository.getStoredUser();
      _currentUser = user;
      if (user != null) {
        // Best-effort, tidak diawait oleh pemanggil - tampilan awal
        // tetap secepat cache lokal, lalu diperbarui diam-diam begitu
        // respons server datang jika ada perbedaan (mis. photoUrl yang
        // baru saja diperbaiki langsung di database).
        unawaited(_refreshFromServerSilently());
      }
      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshFromServerSilently() async {
    final refreshed = await _authRepository.refreshStoredUserFromServer();
    if (refreshed != null) {
      updateUser(refreshed);
    }
  }

  /// Memperbarui user aktif di memori dan memberitahu seluruh subscriber
  void updateUser(AuthUserEntity? newUser) {
    if (_currentUser == newUser) return;

    // Jika photoUrl berubah, evict dari ImageCache jika berupa local image
    if (_currentUser?.photoUrl != null &&
        _currentUser!.photoUrl != newUser?.photoUrl) {
      _evictImageCache(_currentUser!.photoUrl!);
    }

    _currentUser = newUser;
    notifyListeners();
  }

  /// Menghapus sesi aktif di memori
  void clearSession() {
    if (_currentUser?.photoUrl != null) {
      _evictImageCache(_currentUser!.photoUrl!);
    }
    _currentUser = null;
    notifyListeners();
  }

  void _evictImageCache(String path) {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {
      // Abaikan jika tidak tersedia di lingkungan non-UI test
    }
  }
}
