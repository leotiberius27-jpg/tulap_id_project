import 'package:flutter/material.dart';

/// AppThemeMode
/// ----------------------------------------------------------------------
/// Opsi tema global Tulap.id:
/// - system: Mengikuti pengaturan tema perangkat (ThemeMode.system)
/// - light: Tampilan terang standar Tulap.id (ThemeMode.light)
/// - dark: Tampilan gelap kontras tinggi berbasis dark navy (ThemeMode.dark)
/// ----------------------------------------------------------------------
enum AppThemeMode {
  system,
  light,
  dark;

  ThemeMode toFlutterThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  String toCode() => name;

  static AppThemeMode fromCode(String? code) {
    switch (code?.toLowerCase().trim()) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }

  String get label {
    switch (this) {
      case AppThemeMode.system:
        return 'Ikuti Sistem';
      case AppThemeMode.light:
        return 'Mode Terang';
      case AppThemeMode.dark:
        return 'Mode Gelap';
    }
  }

  String get subtitle {
    switch (this) {
      case AppThemeMode.system:
        return 'Menyesuaikan tema perangkat';
      case AppThemeMode.light:
        return 'Tampilan terang Tulap.id';
      case AppThemeMode.dark:
        return 'Nyaman digunakan di kondisi minim cahaya';
    }
  }
}
