import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/app/di/injection_container.dart';
import 'package:tulap_mobile/core/theme/app_theme.dart';
import 'package:tulap_mobile/core/theme/theme_controller.dart';
import 'package:tulap_mobile/features/account/data/datasources/account_local_datasource.dart';
import 'package:tulap_mobile/features/account/domain/entities/account_settings_entity.dart';
import 'package:tulap_mobile/features/account/domain/entities/storage_breakdown_entity.dart';
import 'package:tulap_mobile/features/account/presentation/pages/display_settings_page.dart';

class FakeAccountLocalDataSource implements AccountLocalDataSource {
  AppThemeMode savedMode = AppThemeMode.system;

  @override
  Future<AppThemeMode> getThemeMode() async => savedMode;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    savedMode = mode;
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
  late ThemeController themeController;

  setUp(() {
    fakeDataSource = FakeAccountLocalDataSource();
    themeController = ThemeController(localDataSource: fakeDataSource);

    if (sl.isRegistered<ThemeController>()) {
      sl.unregister<ThemeController>();
    }
    sl.registerSingleton<ThemeController>(themeController);
  });

  tearDown(() {
    if (sl.isRegistered<ThemeController>()) {
      sl.unregister<ThemeController>();
    }
  });

  group('1. AppThemeMode Model & Serialization Tests', () {
    test('fromCode parses strings correctly', () {
      expect(AppThemeMode.fromCode('system'), AppThemeMode.system);
      expect(AppThemeMode.fromCode('light'), AppThemeMode.light);
      expect(AppThemeMode.fromCode('dark'), AppThemeMode.dark);
      expect(AppThemeMode.fromCode('SYSTEM'), AppThemeMode.system);
      expect(AppThemeMode.fromCode(null), AppThemeMode.system);
      expect(AppThemeMode.fromCode('invalid'), AppThemeMode.system);
    });

    test('toFlutterThemeMode maps correctly to Flutter ThemeMode', () {
      expect(AppThemeMode.system.toFlutterThemeMode(), ThemeMode.system);
      expect(AppThemeMode.light.toFlutterThemeMode(), ThemeMode.light);
      expect(AppThemeMode.dark.toFlutterThemeMode(), ThemeMode.dark);
    });

    test('toCode serializes correctly', () {
      expect(AppThemeMode.system.toCode(), 'system');
      expect(AppThemeMode.light.toCode(), 'light');
      expect(AppThemeMode.dark.toCode(), 'dark');
    });

    test('Labels and subtitles match specification', () {
      expect(AppThemeMode.system.label, 'Ikuti Sistem');
      expect(AppThemeMode.light.label, 'Mode Terang');
      expect(AppThemeMode.dark.label, 'Mode Gelap');

      expect(AppThemeMode.system.subtitle, 'Menyesuaikan tema perangkat');
      expect(AppThemeMode.light.subtitle, 'Tampilan terang Tulap.id');
      expect(AppThemeMode.dark.subtitle, 'Nyaman digunakan di kondisi minim cahaya');
    });
  });

  group('2. ThemeController State Management Tests', () {
    test('Default mode is system', () {
      expect(themeController.appThemeMode, AppThemeMode.system);
      expect(themeController.themeMode, ThemeMode.system);
    });

    test('loadTheme loads persisted preference', () async {
      fakeDataSource.savedMode = AppThemeMode.dark;
      await themeController.loadTheme();

      expect(themeController.appThemeMode, AppThemeMode.dark);
      expect(themeController.themeMode, ThemeMode.dark);
      expect(themeController.isLoaded, isTrue);
    });

    test('setThemeMode updates state, saves to datasource, and notifies listeners', () async {
      int listenerCalls = 0;
      themeController.addListener(() => listenerCalls++);

      await themeController.setThemeMode(AppThemeMode.light);
      expect(themeController.appThemeMode, AppThemeMode.light);
      expect(themeController.themeMode, ThemeMode.light);
      expect(fakeDataSource.savedMode, AppThemeMode.light);
      expect(listenerCalls, 1);

      await themeController.setThemeMode(AppThemeMode.dark);
      expect(themeController.appThemeMode, AppThemeMode.dark);
      expect(themeController.themeMode, ThemeMode.dark);
      expect(fakeDataSource.savedMode, AppThemeMode.dark);
      expect(listenerCalls, 2);

      // Setting same mode does not notify unnecessarily
      await themeController.setThemeMode(AppThemeMode.dark);
      expect(listenerCalls, 2);
    });
  });

  group('3. TulapThemeColors & AppTheme Token Integrity Tests', () {
    test('Light palette integrity matches specifications', () {
      const light = TulapThemeColors.light;
      expect(light.background, const Color(0xFFF7F9FC));
      expect(light.surface, const Color(0xFFFFFFFF));
      expect(light.primary, const Color(0xFF00529C));
      expect(light.action, const Color(0xFF0072CE));
      expect(light.textPrimary, const Color(0xFF172033));
    });

    test('Dark palette integrity matches specifications (Dark Navy #0B1220)', () {
      const dark = TulapThemeColors.dark;
      expect(dark.background, const Color(0xFF0B1220));
      expect(dark.surface, const Color(0xFF111C2E));
      expect(dark.surfaceElevated, const Color(0xFF16243A));
      expect(dark.primary, const Color(0xFF4DA3FF));
      expect(dark.action, const Color(0xFF38BDF8));
      expect(dark.textPrimary, const Color(0xFFF8FAFC));
      expect(dark.border, const Color(0xFF27364B));
    });

    test('AppTheme.light and AppTheme.dark have correct brightness and extensions', () {
      final lightTheme = AppTheme.light;
      final darkTheme = AppTheme.dark;

      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);

      expect(lightTheme.extension<TulapThemeColors>(), isNotNull);
      expect(darkTheme.extension<TulapThemeColors>(), isNotNull);
    });
  });

  group('4. DisplaySettingsPage Widget & Interaction Tests', () {
    Widget buildTestWidget({Brightness brightness = Brightness.light}) {
      return MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeController.themeMode,
        home: const DisplaySettingsPage(),
      );
    }

    testWidgets('Renders all 3 theme options in order (Sistem, Terang, Gelap)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tampilan'), findsOneWidget);
      expect(find.text('TEMA APLIKASI'), findsOneWidget);
      expect(find.text('Ikuti Sistem'), findsOneWidget);
      expect(find.text('Mode Terang'), findsOneWidget);
      expect(find.text('Mode Gelap'), findsOneWidget);

      expect(find.text('Menyesuaikan tema perangkat'), findsOneWidget);
      expect(find.text('Tampilan terang Tulap.id'), findsOneWidget);
      expect(find.text('Nyaman digunakan di kondisi minim cahaya'), findsOneWidget);
    });

    testWidgets('Tapping Mode Gelap updates ThemeController immediately', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(themeController.appThemeMode, AppThemeMode.system);

      await tester.tap(find.text('Mode Gelap'));
      await tester.pumpAndSettle();

      expect(themeController.appThemeMode, AppThemeMode.dark);
      expect(fakeDataSource.savedMode, AppThemeMode.dark);
    });

    testWidgets('Tapping Mode Terang updates ThemeController immediately', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mode Terang'));
      await tester.pumpAndSettle();

      expect(themeController.appThemeMode, AppThemeMode.light);
      expect(fakeDataSource.savedMode, AppThemeMode.light);
    });

    testWidgets('Tapping Ikuti Sistem updates ThemeController immediately', (tester) async {
      themeController.setThemeMode(AppThemeMode.dark);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ikuti Sistem'));
      await tester.pumpAndSettle();

      expect(themeController.appThemeMode, AppThemeMode.system);
      expect(fakeDataSource.savedMode, AppThemeMode.system);
    });
  });

  group('5. Multi-Viewport & Font-Scale Responsiveness Tests', () {
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
        testWidgets('DisplaySettingsPage renders without overflow on ${size.width}x${size.height} fontScale $fontScale in Light & Dark', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          // Light mode
          await themeController.setThemeMode(AppThemeMode.light);
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(fontScale),
              ),
              child: MaterialApp(
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: ThemeMode.light,
                home: const DisplaySettingsPage(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Dark mode
          await themeController.setThemeMode(AppThemeMode.dark);
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(fontScale),
              ),
              child: MaterialApp(
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: ThemeMode.dark,
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
