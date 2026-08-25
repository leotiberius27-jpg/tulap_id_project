import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';
import 'package:tulap_mobile/features/task_detail/presentation/pages/create_activity_page.dart';

class _FakeAuthRepo implements AuthRepository {
  @override
  Future<AuthUserEntity?> getCurrentSession() async {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    'CreateActivityPage renders form inputs and default checklist items',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: CreateActivityPage()));

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

    await tester.pumpWidget(const MaterialApp(home: CreateActivityPage()));

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
}
