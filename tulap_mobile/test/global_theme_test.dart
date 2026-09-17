import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/app/di/injection_container.dart';
import 'package:tulap_mobile/core/localization/app_language.dart';
import 'package:tulap_mobile/core/localization/language_controller.dart';
import 'package:tulap_mobile/core/theme/app_theme.dart';
import 'package:tulap_mobile/features/account/data/datasources/account_local_datasource.dart';
import 'package:tulap_mobile/features/account/domain/entities/account_settings_entity.dart';
import 'package:tulap_mobile/features/account/domain/entities/storage_breakdown_entity.dart';
import 'package:tulap_mobile/features/account/presentation/pages/display_settings_page.dart';

class FakeAccountLocalDataSource implements AccountLocalDataSource {
  AppLanguage savedLanguage = AppLanguage.id;

  @override
  Future<AppLanguage> getLanguage() async => savedLanguage;

  @override
  Future<void> saveLanguage(AppLanguage language) async {
    savedLanguage = language;
  }

  @override
  Future<CameraSettingsEntity> getCameraSettings() async => const CameraSettingsEntity();

  @override
  Future<void> saveCameraSettings(CameraSettingsEntity settings) async {}

  @override
  Future<NotificationSettingsEntity> getNotificationSettings() async =>
      const NotificationSettingsEntity();

  @override
  Future<void> saveNotificationSettings(NotificationSettingsEntity settings) async {}

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

  setUp(() {
    fakeDataSource = FakeAccountLocalDataSource();
    languageController = LanguageController(localDataSource: fakeDataSource);

    if (sl.isRegistered<LanguageController>()) {
      sl.unregister<LanguageController>();
    }
    sl.registerSingleton<LanguageController>(languageController);
  });

  tearDown(() {
    if (sl.isRegistered<LanguageController>()) {
      sl.unregister<LanguageController>();
    }
  });

  group('1. TulapThemeColors & AppTheme Token Integrity Tests', () {
    test('Light palette integrity matches specifications', () {
      const light = TulapThemeColors.light;
      expect(light.background, const Color(0xFFF8FAFC));
      expect(light.surface, const Color(0xFFFFFFFF));
      expect(light.primary, const Color(0xFF0057B8));
      expect(light.action, const Color(0xFF0057B8));
      expect(light.textPrimary, const Color(0xFF0F172A));
    });

    test('AppTheme.light has correct brightness and extensions', () {
      final lightTheme = AppTheme.light;

      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.extension<TulapThemeColors>(), isNotNull);
    });
  });

  group('2. DisplaySettingsPage Widget & Interaction Tests', () {
    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.light,
        home: const DisplaySettingsPage(),
      );
    }

    testWidgets('Renders language options, no theme switcher', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Bahasa'), findsOneWidget);
      expect(find.text('BAHASA / LANGUAGE'), findsOneWidget);
      expect(find.text('Bahasa Indonesia'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Dark mode picker was removed from the app entirely.
      expect(find.text('TEMA APLIKASI'), findsNothing);
      expect(find.text('Mode Gelap'), findsNothing);
    });

    testWidgets('Tapping English updates LanguageController immediately', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(languageController.currentLanguage, AppLanguage.id);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(languageController.currentLanguage, AppLanguage.en);
      expect(fakeDataSource.savedLanguage, AppLanguage.en);
    });
  });

  group('3. Multi-Viewport & Font-Scale Responsiveness Tests', () {
    final viewports = [
      const Size(320, 640),
      const Size(360, 780),
      const Size(375, 812),
      const Size(390, 844),
      const Size(412, 915),
      const Size(430, 932),
    ];

    final fontScales = [1.0, 1.3, 1.5];

    for (final size in viewports) {
      for (final fontScale in fontScales) {
        testWidgets('DisplaySettingsPage renders without overflow on ${size.width}x${size.height} fontScale $fontScale', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(fontScale),
              ),
              child: MaterialApp(
                theme: AppTheme.light,
                home: const DisplaySettingsPage(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
