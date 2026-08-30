import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/app/di/injection_container.dart';
import 'package:tulap_mobile/core/localization/app_language.dart';
import 'package:tulap_mobile/core/localization/app_localizations.dart';
import 'package:tulap_mobile/core/localization/language_controller.dart';
import 'package:tulap_mobile/core/theme/app_theme.dart';
import 'package:tulap_mobile/core/theme/app_theme_mode.dart';
import 'package:tulap_mobile/core/theme/theme_controller.dart';
import 'package:tulap_mobile/features/account/data/datasources/account_local_datasource.dart';
import 'package:tulap_mobile/features/account/domain/entities/account_settings_entity.dart';
import 'package:tulap_mobile/features/account/domain/entities/storage_breakdown_entity.dart';
import 'package:tulap_mobile/features/account/presentation/pages/language_settings_page.dart';

class FakeAccountLocalDataSource implements AccountLocalDataSource {
  AppThemeMode savedThemeMode = AppThemeMode.light;
  AppLanguage savedLanguage = AppLanguage.id;

  @override
  Future<AppThemeMode> getThemeMode() async => savedThemeMode;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    savedThemeMode = mode;
  }

  @override
  Future<AppLanguage> getLanguage() async => savedLanguage;

  @override
  Future<void> saveLanguage(AppLanguage language) async {
    savedLanguage = language;
  }

  @override
  Future<CameraSettingsEntity> getCameraSettings() async =>
      const CameraSettingsEntity();

  @override
  Future<void> saveCameraSettings(CameraSettingsEntity settings) async {}

  @override
  Future<NotificationSettingsEntity> getNotificationSettings() async =>
      const NotificationSettingsEntity();

  @override
  Future<void> saveNotificationSettings(
      NotificationSettingsEntity settings) async {}

  @override
  Future<StorageBreakdownEntity> getStorageBreakdown() async =>
      const StorageBreakdownEntity(
        cacheBytes: 0,
        photosBytes: 0,
        databaseBytes: 0,
        pendingUploadsCount: 0,
        totalBytes: 0,
      );

  @override
  Future<int> clearTemporaryCache() async => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAccountLocalDataSource fakeDataSource;
  late LanguageController languageController;
  late ThemeController themeController;

  setUp(() {
    fakeDataSource = FakeAccountLocalDataSource();
    languageController = LanguageController(localDataSource: fakeDataSource);
    themeController = ThemeController(localDataSource: fakeDataSource);

    if (sl.isRegistered<LanguageController>()) {
      sl.unregister<LanguageController>();
    }
    sl.registerSingleton<LanguageController>(languageController);

    if (sl.isRegistered<ThemeController>()) {
      sl.unregister<ThemeController>();
    }
    sl.registerSingleton<ThemeController>(themeController);
  });

  tearDown(() {
    if (sl.isRegistered<LanguageController>()) {
      sl.unregister<LanguageController>();
    }
    if (sl.isRegistered<ThemeController>()) {
      sl.unregister<ThemeController>();
    }
  });

  group('1. AppLanguage Model & Enum Tests', () {
    test('fromCode parses English and Indonesian correctly', () {
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
      expect(AppLanguage.fromCode('english'), AppLanguage.en);
      expect(AppLanguage.fromCode('id'), AppLanguage.id);
      expect(AppLanguage.fromCode('indonesia'), AppLanguage.id);
      expect(AppLanguage.fromCode(null), AppLanguage.id);
      expect(AppLanguage.fromCode('unknown'), AppLanguage.id);
    });

    test('Properties (code, locale, flag, label) match specification', () {
      expect(AppLanguage.id.code, 'id');
      expect(AppLanguage.id.locale, const Locale('id', 'ID'));
      expect(AppLanguage.id.label, 'Bahasa Indonesia');
      expect(AppLanguage.id.flag, '🇮🇩');

      expect(AppLanguage.en.code, 'en');
      expect(AppLanguage.en.locale, const Locale('en', 'US'));
      expect(AppLanguage.en.label, 'English');
      expect(AppLanguage.en.flag, '🇬🇧');
    });
  });

  group('2. LanguageController State Management Tests', () {
    test('Default language is Indonesian (id)', () {
      expect(languageController.currentLanguage, AppLanguage.id);
      expect(languageController.currentLocale, const Locale('id', 'ID'));
      expect(languageController.isIndonesian, isTrue);
      expect(languageController.isEnglish, isFalse);
    });

    test('loadLanguage loads persisted language preference', () async {
      fakeDataSource.savedLanguage = AppLanguage.en;
      await languageController.loadLanguage();

      expect(languageController.currentLanguage, AppLanguage.en);
      expect(languageController.currentLocale, const Locale('en', 'US'));
      expect(languageController.isEnglish, isTrue);
      expect(languageController.isLoaded, isTrue);
    });

    test('setLanguage updates state, notifies listeners, and persists', () async {
      int listenerCalls = 0;
      languageController.addListener(() => listenerCalls++);

      await languageController.setLanguage(AppLanguage.en);
      expect(languageController.currentLanguage, AppLanguage.en);
      expect(fakeDataSource.savedLanguage, AppLanguage.en);
      expect(listenerCalls, 1);

      await languageController.setLanguage(AppLanguage.id);
      expect(languageController.currentLanguage, AppLanguage.id);
      expect(fakeDataSource.savedLanguage, AppLanguage.id);
      expect(listenerCalls, 2);

      // Setting same language does not trigger duplicate notifications
      await languageController.setLanguage(AppLanguage.id);
      expect(listenerCalls, 2);
    });
  });

  group('3. AppLocalizations Dictionary Tests', () {
    test('Indonesian strings match expected values', () {
      final l10nId = AppLocalizations(const Locale('id', 'ID'));
      expect(l10nId.isIndonesian, isTrue);
      expect(l10nId.isEnglish, isFalse);
      expect(l10nId.tabHome, 'Beranda');
      expect(l10nId.tabTasks, 'Tugas');
      expect(l10nId.tabHistory, 'Riwayat');
      expect(l10nId.tabAccount, 'Akun');
      expect(l10nId.travelMission, 'Perjalanan Dinas');
      expect(l10nId.settings, 'Pengaturan');
      expect(l10nId.language, 'Bahasa');
      expect(l10nId.greeting(8), 'Selamat pagi,');
      expect(l10nId.greeting(13), 'Selamat siang,');
      expect(l10nId.greeting(16), 'Selamat sore,');
      expect(l10nId.greeting(20), 'Selamat malam,');
    });

    test('English strings match expected values', () {
      final l10nEn = AppLocalizations(const Locale('en', 'US'));
      expect(l10nEn.isEnglish, isTrue);
      expect(l10nEn.isIndonesian, isFalse);
      expect(l10nEn.tabHome, 'Home');
      expect(l10nEn.tabTasks, 'Tasks');
      expect(l10nEn.tabHistory, 'History');
      expect(l10nEn.tabAccount, 'Account');
      expect(l10nEn.travelMission, 'Travel Mission');
      expect(l10nEn.settings, 'Settings');
      expect(l10nEn.language, 'Language');
      expect(l10nEn.greeting(8), 'Good morning,');
      expect(l10nEn.greeting(14), 'Good afternoon,');
      expect(l10nEn.greeting(19), 'Good evening,');
    });
  });

  group('4. LanguageSettingsPage Widget & Interaction Tests', () {
    Widget buildTestWidget() {
      return ListenableBuilder(
        listenable: languageController,
        builder: (context, _) {
          return MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            locale: languageController.currentLocale,
            supportedLocales: const [
              Locale('id', 'ID'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const LanguageSettingsPage(),
          );
        },
      );
    }

    testWidgets('Renders both language options (Bahasa Indonesia & English)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Bahasa Indonesia'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('🇮🇩'), findsOneWidget);
      expect(find.text('🇬🇧'), findsOneWidget);
    });

    testWidgets('Tapping English switches language immediately to English', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(languageController.currentLanguage, AppLanguage.id);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(languageController.currentLanguage, AppLanguage.en);
      expect(fakeDataSource.savedLanguage, AppLanguage.en);
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('Tapping Bahasa Indonesia switches language back to Indonesian', (tester) async {
      await languageController.setLanguage(AppLanguage.en);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(languageController.currentLanguage, AppLanguage.en);

      await tester.tap(find.text('Bahasa Indonesia'));
      await tester.pumpAndSettle();

      expect(languageController.currentLanguage, AppLanguage.id);
      expect(fakeDataSource.savedLanguage, AppLanguage.id);
      expect(find.text('Bahasa'), findsOneWidget);
    });
  });
}
