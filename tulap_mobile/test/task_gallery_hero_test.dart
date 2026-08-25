import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';
import 'package:tulap_mobile/features/task_detail/presentation/widgets/task_gallery_hero.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyTask = TaskEntity(
    id: 'TL-202608-0001',
    taskCode: 'TLP-2026-08-001',
    taskName: 'Monitoring Kendaraan Dinas',
    destination: 'Jl. Cenderawasih, Timika',
    startDate: DateTime(2026, 8, 24, 9, 0),
    endDate: DateTime(2026, 8, 24, 12, 0),
    budgetAmount: 1500000,
    status: TaskStatusEntity.ongoing,
    assigneeId: 'usr_01',
    assigneeName: 'Leonardo',
    checklistItems: const [],
    geotagPhotoCount: 4,
    expenseNoteCount: 0,
  );

  List<GeotagPhotoEntity> createDummyPhotos(int count) {
    return List.generate(
      count,
      (i) => GeotagPhotoEntity(
        id: 'photo-$i',
        taskId: 'TL-202608-0001',
        localFilePath: 'assets/images/referensi/01.png',
        latitude: -4.546123 + (i * 0.0001),
        longitude: 136.887421 + (i * 0.0001),
        gpsAccuracyMeters: 5.0 + i,
        plusCode: '6P28+3Q',
        serverTimestamp: DateTime.now(),
        integrityHash: 'sha256-hash-$i',
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
        caption: 'Foto Bukti #${i + 1}',
      ),
    );
  }

  testWidgets(
    'Test A: 4 Photos - swipe forward and backward with dynamic indicators',
    (WidgetTester tester) async {
      final photos = createDummyPhotos(4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskGalleryHero(
              photos: photos,
              task: dummyTask,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State: Page 1 of 4
      expect(find.text('1/4'), findsOneWidget);
      expect(find.text('Foto Bukti #1'), findsOneWidget);

      // 2. Swipe Left -> Page 2 of 4
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('2/4'), findsOneWidget);
      expect(find.text('Foto Bukti #2'), findsOneWidget);

      // 3. Swipe Left -> Page 3 of 4
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('3/4'), findsOneWidget);
      expect(find.text('Foto Bukti #3'), findsOneWidget);

      // 4. Swipe Left -> Page 4 of 4
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('4/4'), findsOneWidget);
      expect(find.text('Foto Bukti #4'), findsOneWidget);

      // 5. Swipe Right -> Return to Page 3 of 4
      await tester.fling(find.byType(PageView), const Offset(500, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('3/4'), findsOneWidget);
      expect(find.text('Foto Bukti #3'), findsOneWidget);

      // 6. Swipe Right -> Return to Page 2 of 4
      await tester.fling(find.byType(PageView), const Offset(500, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('2/4'), findsOneWidget);
      expect(find.text('Foto Bukti #2'), findsOneWidget);

      // 7. Swipe Right -> Return to Page 1 of 4
      await tester.fling(find.byType(PageView), const Offset(500, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('1/4'), findsOneWidget);
      expect(find.text('Foto Bukti #1'), findsOneWidget);
    },
  );

  testWidgets('Test B: 1 Photo - renders 1/1 without dots indicator', (
    WidgetTester tester,
  ) async {
    final photos = createDummyPhotos(1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskGalleryHero(photos: photos, task: dummyTask, onBack: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('Foto Bukti #1'), findsOneWidget);
  });

  testWidgets('Test C: 0 Photos - renders fallback empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskGalleryHero(
            photos: const [],
            task: dummyTask,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada bukti kegiatan'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });
}
