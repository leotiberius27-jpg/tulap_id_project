import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// AppLocalizations
/// ----------------------------------------------------------------------
/// Sistem lokalisasi dwibahasa Tulap.id (Bahasa Indonesia & English).
/// Mendukung akses melalui:
/// - `AppLocalizations.of(context)`
/// - `context.l10n`
/// ----------------------------------------------------------------------
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('id', 'ID'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isEnglish => locale.languageCode == 'en';
  bool get isIndonesian => locale.languageCode == 'id';

  // ==========================================================================
  // NAVIGATION & SHELL
  // ==========================================================================
  String get tabHome => isEnglish ? 'Home' : 'Beranda';
  String get tabTasks => isEnglish ? 'Tasks' : 'Tugas';
  String get tabHistory => isEnglish ? 'History' : 'Riwayat';
  String get tabAccount => isEnglish ? 'Account' : 'Akun';
  String get openCamera => isEnglish ? 'Open Geotag Camera' : 'Buka Kamera Geotag';

  // ==========================================================================
  // GREETINGS & HEADER
  // ==========================================================================
  String greeting(int hour) {
    if (isEnglish) {
      if (hour >= 5 && hour < 12) return 'Good morning,';
      if (hour >= 12 && hour < 17) return 'Good afternoon,';
      return 'Good evening,';
    } else {
      if (hour >= 5 && hour < 11) return 'Selamat pagi,';
      if (hour >= 11 && hour < 15) return 'Selamat siang,';
      if (hour >= 15 && hour < 18) return 'Selamat sore,';
      return 'Selamat malam,';
    }
  }

  String get notifications => isEnglish ? 'Notifications' : 'Notifikasi';
  String get settings => isEnglish ? 'Settings' : 'Pengaturan';
  String get displayTheme => isEnglish ? 'Display & Theme' : 'Tampilan & Tema';
  String get language => isEnglish ? 'Language' : 'Bahasa';
  String get selectLanguage => isEnglish ? 'Select Language' : 'Pilih Bahasa';

  // ==========================================================================
  // DASHBOARD & HOME
  // ==========================================================================
  String get activeMissionTitle => isEnglish ? 'Active Task' : 'Tugas Utama Aktif';
  String get quickActions => isEnglish ? 'Quick Actions' : 'Aksi Cepat';
  String get travelMission => isEnglish ? 'Travel Mission' : 'Perjalanan Dinas';
  String get scanReceipt => isEnglish ? 'Scan Receipt' : 'Scan Nota';
  String get syncCenter => isEnglish ? 'Sync Center' : 'Pusat Sinkronisasi';
  String get lpjSummary => isEnglish ? 'LPJ Summary' : 'Ringkasan LPJ';
  String get myActivities => isEnglish ? 'My Activities' : 'Kegiatan Saya';
  String get viewAll => isEnglish ? 'View All' : 'Lihat Semua';
  String get fieldStatistics => isEnglish ? 'Field Statistics' : 'Statistik Lapangan';
  String get operationalBudget => isEnglish ? 'Operational Budget' : 'Anggaran Operasional';

  // ==========================================================================
  // TRAVEL MISSION (PERJALANAN DINAS)
  // ==========================================================================
  String get travelMissionTitle => isEnglish ? 'Travel Mission' : 'Perjalanan Dinas';
  String get newTravelMission => isEnglish ? '+ New Travel Mission' : '+ Buat Perjalanan Dinas Baru';
  String get createTravelMission => isEnglish ? 'Create Travel Mission' : 'Buat Perjalanan Dinas';
  String get missionDestination => isEnglish ? 'Destination' : 'Tujuan';
  String get missionOrigin => isEnglish ? 'Origin City' : 'Kota Asal';
  String get estimatedBudget => isEnglish ? 'Estimated Budget' : 'Estimasi Anggaran';
  String get transportMode => isEnglish ? 'Transport Mode' : 'Moda Transportasi';
  String get selectTransportMode => isEnglish ? 'Select Transport Mode' : 'Pilih Moda Transportasi';
  String get itinerarySummary => isEnglish ? 'Itinerary Summary Sheet' : 'Lembar Ringkasan Rencana Perjalanan';
  String get saveAndPublishMission => isEnglish ? 'Save & Publish Mission' : 'Simpan & Terbitkan Perjalanan';
  String get supportingDocuments => isEnglish ? 'Supporting Documents' : 'Dokumen Pendukung';
  String get uploadDocument => isEnglish ? 'Upload Document' : 'Unggah Dokumen';
  String get docUploadedSuccess => isEnglish ? 'Document successfully attached!' : 'Dokumen berhasil dilampirkan!';
  String get viewDoc => isEnglish ? 'VIEW' : 'LIHAT';

  // ==========================================================================
  // SETTINGS & ACCOUNT
  // ==========================================================================
  String get accountAndSecurity => isEnglish ? 'ACCOUNT & SECURITY' : 'AKUN & KEAMANAN';
  String get dataAndSync => isEnglish ? 'DATA & SYNCHRONIZATION' : 'DATA & SINKRONISASI';
  String get appSettings => isEnglish ? 'APP SETTINGS' : 'PENGATURAN';
  String get helpAndInfo => isEnglish ? 'HELP & INFORMATION' : 'BANTUAN & INFORMASI';
  String get profileInfo => isEnglish ? 'Profile Information' : 'Informasi Profil';
  String get securityLogin => isEnglish ? 'Security & Login' : 'Keamanan & Login';
  String get deviceStorage => isEnglish ? 'Storage & Cache' : 'Penyimpanan & Cache';
  String get cameraDocumentation => isEnglish ? 'Camera & Documentation' : 'Kamera & Dokumentasi';
  String get locationGps => isEnglish ? 'Location & GPS' : 'Lokasi & GPS';
  String get appearance => isEnglish ? 'Display' : 'Tampilan';
  String get appearanceSubtitle => isEnglish ? 'Light, dark, & system mode' : 'Mode terang, gelap, & sistem';
  String get languageSubtitle => isEnglish ? 'Choose English or Bahasa Indonesia' : 'Pilih Bahasa Indonesia atau English';
  String get logout => isEnglish ? 'Logout' : 'Keluar Akun';

  // ==========================================================================
  // THEME MODES
  // ==========================================================================
  String get themeFollowSystem => isEnglish ? 'Follow System' : 'Ikuti Sistem';
  String get themeFollowSystemSub => isEnglish ? 'Light appearance standard' : 'Standar tampilan terang';
  String get themeLight => isEnglish ? 'Light Mode' : 'Mode Terang';
  String get themeLightSub => isEnglish ? 'Clean & bright standard' : 'Tampilan terang Tulap.id';
  String get themeDark => isEnglish ? 'Dark Mode' : 'Mode Gelap';
  String get themeDarkSub => isEnglish ? 'Comfortable for low-light' : 'Nyaman digunakan di kondisi minim cahaya';

  // ==========================================================================
  // COMMON ACTIONS
  // ==========================================================================
  String get save => isEnglish ? 'Save' : 'Simpan';
  String get cancel => isEnglish ? 'Cancel' : 'Batal';
  String get back => isEnglish ? 'Back' : 'Kembali';
  String get delete => isEnglish ? 'Delete' : 'Hapus';
  String get close => isEnglish ? 'Close' : 'Tutup';
  String get success => isEnglish ? 'Success' : 'Berhasil';
  String get loading => isEnglish ? 'Loading...' : 'Memuat...';
  String get retry => isEnglish ? 'Retry' : 'Coba Lagi';
  String get search => isEnglish ? 'Search' : 'Cari';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['id', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
