import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tulap_mobile/core/theme/app_theme.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';
import 'package:tulap_mobile/features/task_detail/presentation/pages/create_activity_page.dart';

class _FakeAuthRepo implements AuthRepository {
  @override
  Future<AuthUserEntity?> getStoredUser() async {
    return const AuthUserEntity(
      id: 'usr-1',
      nip: '19900101',
      fullName: 'Leonardo Tester',
      email: 'leo@tulap.id',
      role: 'OFFICER',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildLocalizedApp({
  required Widget home,
  ThemeData? theme,
}) {
  return MaterialApp(
    title: 'Tulap.id Test',
    theme: theme ?? AppTheme.light,
    locale: const Locale('id', 'ID'),
    supportedLocales: const [
      Locale('id', 'ID'),
      Locale('en', 'US'),
    ],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    final sl = GetIt.instance;
    if (!sl.isRegistered<GetCurrentSession>()) {
      sl.registerLazySingleton<GetCurrentSession>(
        () => GetCurrentSession(_FakeAuthRepo()),
      );
    }
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets(
    'MaterialLocalizations resolves normally under localized Tulap root',
    (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        _buildLocalizedApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const Scaffold(body: Text('OK'));
            },
          ),
        ),
      );

      final localizations = MaterialLocalizations.of(capturedContext);
      expect(localizations, isNotNull);
      expect(localizations.okButtonLabel, isNotEmpty);
      expect(localizations.cancelButtonLabel, isNotEmpty);
    },
  );

  testWidgets(
    'CreateActivityPage renders form inputs and default checklist items',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildLocalizedApp(home: const CreateActivityPage()));
      await tester.pumpAndSettle();

      expect(find.text('Buat Kegiatan Lapangan'), findsOneWidget);
      expect(find.text('Nama Kegiatan Lapangan *'), findsOneWidget);
      expect(find.text('Lokasi / Destinasi *'), findsOneWidget);
      expect(find.text('CHECKLIST LAPANGAN'), findsOneWidget);
      expect(
        find.text('Tiba di Lokasi & Verifikasi Koordinat'),
        findsOneWidget,
      );
      expect(
        find.text('Pemeriksaan / Observasi Fisik Lapangan'),
        findsOneWidget,
      );
      expect(find.text('Simpan & Mulai Kegiatan'), findsOneWidget);
    },
  );

  testWidgets('Allows adding and removing custom checklist items dynamically', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildLocalizedApp(home: const CreateActivityPage()));
    await tester.pumpAndSettle();

    // Initial count is 4
    expect(find.text('4 butir'), findsOneWidget);

    // Add new checklist item
    final inputFinder = find.widgetWithText(
      TextField,
      'Tambah butir checklist...',
    );
    await tester.enterText(inputFinder, 'Wawancara dengan Pemilik Toko');
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();

    expect(find.text('5 butir'), findsOneWidget);
    expect(find.text('Wawancara dengan Pemilik Toko'), findsOneWidget);

    // Remove the first item
    final deleteButtons = find.byIcon(Icons.close_rounded);
    await tester.tap(deleteButtons.first);
    await tester.pump();

    expect(find.text('4 butir'), findsOneWidget);
  });

  testWidgets(
    'DatePicker opens normally without MaterialLocalizations crash',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildLocalizedApp(
          home: const CreateActivityPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Tanggal Kegiatan input decorator
      final datePickerFinder = find.widgetWithText(InputDecorator, 'Tanggal Kegiatan *');
      expect(datePickerFinder, findsOneWidget);

      await tester.tap(datePickerFinder);
      await tester.pumpAndSettle();

      // DatePickerDialog is open
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Tap cancel button (first button in DatePickerDialog actions)
      final dialogButtons = find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextButton),
      );
      expect(dialogButtons, findsAtLeastNWidgets(2));
      await tester.tap(dialogButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
    },
  );

  testWidgets(
    'Multi-day toggle enables start and end date pickers with Indonesian formatting',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildLocalizedApp(
          home: const CreateActivityPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle multi-day switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Start and End date fields appear
      expect(find.widgetWithText(InputDecorator, 'Tanggal Mulai *'), findsOneWidget);
      expect(find.widgetWithText(InputDecorator, 'Tanggal Selesai *'), findsOneWidget);

      // Tap Tanggal Selesai
      await tester.tap(find.widgetWithText(InputDecorator, 'Tanggal Selesai *'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Tap OK button in dialog
      final dialogButtons = find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextButton),
      );
      expect(dialogButtons, findsAtLeastNWidgets(2));
      await tester.tap(dialogButtons.last);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
    },
  );
}
