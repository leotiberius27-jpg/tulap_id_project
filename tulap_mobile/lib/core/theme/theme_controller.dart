import 'package:flutter/material.dart';
import '../../features/account/data/datasources/account_local_datasource.dart';
import 'app_theme_mode.dart';

/// ThemeController
/// ----------------------------------------------------------------------
/// State manager global untuk preferensi tema aplikasi Tulap.id.
/// - Memuat preferensi tema dari local secure storage saat startup
/// - Mengubah tema secara instan tanpa reload halaman / restart app
/// - Menyediakan AppThemeMode (system, light, dark) dan Flutter ThemeMode
/// ----------------------------------------------------------------------
class ThemeController extends ChangeNotifier {
  final AccountLocalDataSource _localDataSource;
  AppThemeMode _currentMode = AppThemeMode.system;
  bool _isLoaded = false;

  ThemeController({required AccountLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  AppThemeMode get appThemeMode => _currentMode;
  ThemeMode get themeMode => _currentMode.toFlutterThemeMode();
  bool get isLoaded => _isLoaded;

  /// Memuat preferensi tema dari local storage (offline-first)
  Future<void> loadTheme() async {
    final mode = await _localDataSource.getThemeMode();
    _currentMode = mode;
    _isLoaded = true;
    notifyListeners();
  }

  /// Mengatur tema dan menyimpannya secara persisten ke local storage
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_currentMode == mode) return;
    _currentMode = mode;
    notifyListeners();
    await _localDataSource.saveThemeMode(mode);
  }
}
