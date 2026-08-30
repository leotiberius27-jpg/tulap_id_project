import 'package:flutter/material.dart';

/// AppLanguage
/// ----------------------------------------------------------------------
/// Dukungan dwibahasa Tulap.id:
/// - id: Bahasa Indonesia (Standar Nasional)
/// - en: English (Standard / International)
/// ----------------------------------------------------------------------
enum AppLanguage {
  id,
  en;

  String get code => name;

  Locale get locale {
    switch (this) {
      case AppLanguage.id:
        return const Locale('id', 'ID');
      case AppLanguage.en:
        return const Locale('en', 'US');
    }
  }

  String get label {
    switch (this) {
      case AppLanguage.id:
        return 'Bahasa Indonesia';
      case AppLanguage.en:
        return 'English';
    }
  }

  String get subtitle {
    switch (this) {
      case AppLanguage.id:
        return 'Bahasa baku nasional (Indonesia)';
      case AppLanguage.en:
        return 'English (International)';
    }
  }

  String get flag {
    switch (this) {
      case AppLanguage.id:
        return '🇮🇩';
      case AppLanguage.en:
        return '🇬🇧';
    }
  }

  static AppLanguage fromCode(String? code) {
    switch (code?.toLowerCase().trim()) {
      case 'en':
      case 'english':
        return AppLanguage.en;
      case 'id':
      case 'indonesia':
      default:
        return AppLanguage.id;
    }
  }
}
