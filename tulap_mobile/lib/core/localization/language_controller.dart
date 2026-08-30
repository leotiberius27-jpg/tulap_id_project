import 'package:flutter/material.dart';
import '../../features/account/data/datasources/account_local_datasource.dart';
import 'app_language.dart';

/// LanguageController
/// ----------------------------------------------------------------------
/// State manager global untuk preferensi bahasa Tulap.id (id / en).
/// - Memuat preferensi bahasa dari local storage secara persisten
/// - Mengubah bahasa aplikasi secara instan tanpa perlu restart app
/// ----------------------------------------------------------------------
class LanguageController extends ChangeNotifier {
  final AccountLocalDataSource _localDataSource;
  AppLanguage _currentLanguage = AppLanguage.id;
  bool _isLoaded = false;

  LanguageController({required AccountLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  AppLanguage get currentLanguage => _currentLanguage;
  Locale get currentLocale => _currentLanguage.locale;
  bool get isLoaded => _isLoaded;
  bool get isEnglish => _currentLanguage == AppLanguage.en;
  bool get isIndonesian => _currentLanguage == AppLanguage.id;

  /// Memuat preferensi bahasa dari local storage saat startup
  Future<void> loadLanguage() async {
    final lang = await _localDataSource.getLanguage();
    _currentLanguage = lang;
    _isLoaded = true;
    notifyListeners();
  }

  /// Mengubah bahasa dan menyimpannya secara persisten
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
    await _localDataSource.saveLanguage(language);
  }
}
