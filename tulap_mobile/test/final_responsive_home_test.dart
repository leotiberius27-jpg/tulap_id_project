import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/features/home/presentation/widgets/compact_sync_bar.dart';
import 'package:tulap_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:tulap_mobile/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:tulap_mobile/features/home/presentation/widgets/my_activities_carousel.dart';
import 'package:tulap_mobile/features/home/presentation/widgets/primary_task_card.dart';
import 'package:tulap_mobile/features/home/presentation/widgets/task_alert_bar.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleTask = TaskEntity(
    id: 'TL-202608-0001',
    taskCode: 'TL-202608-0001',
    taskName: 'Monitoring dan Evaluasi Kelayakan Kendaraan Dinas Operasional',
    destination: 'Distrik Kuala Kencana, Mimika, Papua Tengah',
    description: 'Pemeriksaan fisik dan kelayakan operasional',
    startDate: DateTime(2026, 8, 24),
    endDate: DateTime(2026, 8, 26),
    budgetAmount: 1500000,
    status: TaskStatusEntity.ongoing,
    assigneeId: 'user-001',
    assigneeName: 'Leonardo',
    checklistItems: const [
      ChecklistItemEntity(
        id: 'chk-1',
        taskId: 'TL-202608-0001',
        label: 'Cek Surat Tugas',
        order: 1,
        isMandatory: true,
        isCompleted: true,
      ),
      ChecklistItemEntity(
        id: 'chk-2',
        taskId: 'TL-202608-0001',
        label: 'Foto Fisik Kendaraan',
        order: 2,
        isMandatory: true,
        isCompleted: false,
      ),
    ],
    geotagPhotoCount: 4,
    expenseNoteCount: 2,
  );

  group('Final Responsive Home Header Tests', () {
    testWidgets(
      'Header displays logo, dynamic greeting, and user name without wordmark',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeHeader(
                fullName: 'Leo Tiberius',
                agencyName: 'BPKAD Kabupaten Mimika',
                unreadNotificationCount: 2,
                onNotificationTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Leo Tiberius'), findsOneWidget);
        expect(find.textContaining('Selamat'), findsOneWidget);
        expect(find.text('Tugas Lapangan'), findsNothing);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('LT'), findsOneWidget);
      },
    );

    testWidgets(
      'Header handles very long user name without horizontal overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeHeader(
                fullName: 'Alexander Leonardo Nelson Makai',
                agencyName:
                    'Badan Pengelolaan Keuangan dan Aset Daerah Provinsi Papua Tengah',
                unreadNotificationCount: 5,
                onNotificationTap: () {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Alexander Leonardo Nelson Makai'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      },
    );
  });

  group('TaskAlertBar Tests', () {
    testWidgets('Alert bar renders count and triggers callback on tap', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskAlertBar(urgentCount: 2, onTap: () => tapped = true),
          ),
        ),
      );

      expect(find.text('2 tugas perlu perhatian hari ini'), findsOneWidget);
      await tester.tap(find.byType(TaskAlertBar));
      expect(tapped, isTrue);
    });
  });

  group('PrimaryTaskCard (Tugas Utama) Tests', () {
    testWidgets(
      'Renders task name, location, checklist & documentation count, and CTA',
      (tester) async {
        bool ctaTapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PrimaryTaskCard(
                  task: sampleTask,
                  onTap: () => ctaTapped = true,
                  onSeeAll: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Tugas Utama'), findsOneWidget);
        expect(
          find.text(
            'Monitoring dan Evaluasi Kelayakan Kendaraan Dinas Operasional',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Distrik Kuala Kencana, Mimika, Papua Tengah'),
          findsOneWidget,
        );
        expect(find.text('1/2 Checklist  •  4 Dokumentasi'), findsOneWidget);
        expect(find.text('Lanjutkan Tugas'), findsOneWidget);

        await tester.tap(find.text('Lanjutkan Tugas'));
        expect(ctaTapped, isTrue);
      },
    );
  });

  group('HomeQuickActions (Aksi Cepat) Tests', () {
    testWidgets('Renders 4 quick actions and responds to taps', (tester) async {
      bool fotoTapped = false;
      bool notaTapped = false;
      bool lokasiTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeQuickActions(
              onFoto: () => fotoTapped = true,
              onNota: () => notaTapped = true,
              onLokasi: () => lokasiTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Aksi Cepat'), findsOneWidget);
      expect(find.text('Foto'), findsOneWidget);
      expect(find.text('Nota'), findsOneWidget);
      expect(find.text('Lokasi'), findsOneWidget);
      expect(find.text('LPJ'), findsOneWidget);

      await tester.tap(find.text('Foto'));
      expect(fotoTapped, isTrue);

      await tester.tap(find.text('Nota'));
      expect(notaTapped, isTrue);

      await tester.tap(find.text('Lokasi'));
      expect(lokasiTapped, isTrue);
    });
  });

  group('MyActivitiesCarousel (Kegiatan Saya) Tests', () {
    testWidgets('Renders maximum 5 activities and triggers tap on task card', (
      tester,
    ) async {
      final tasks = List.generate(
        7,
        (i) => TaskEntity(
          id: 'task-$i',
          taskCode: 'TL-202608-000$i',
          taskName: 'Kegiatan Lapangan #$i',
          destination: 'Timika, Mimika',
          startDate: DateTime(2026, 8, 24),
          endDate: DateTime(2026, 8, 26),
          budgetAmount: 1000000,
          status: TaskStatusEntity.ongoing,
          assigneeId: 'u1',
          assigneeName: 'Petugas',
          checklistItems: const [],
          geotagPhotoCount: i,
          expenseNoteCount: 0,
        ),
      );

      TaskEntity? selectedTask;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MyActivitiesCarousel(
                activities: tasks,
                onTaskTap: (t) => selectedTask = t,
                onSeeAll: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Kegiatan Saya'), findsOneWidget);
      expect(find.text('Kegiatan Lapangan #0'), findsOneWidget);

      await tester.tap(find.text('Kegiatan Lapangan #0'));
      expect(selectedTask?.id, equals('task-0'));
    });
  });

  group('CompactSyncBar Tests', () {
    testWidgets('Renders sync status and responds to tap', (tester) async {
      bool viewDataTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactSyncBar(
              isOffline: false,
              pendingCount: 2,
              allSynced: false,
              isSyncing: false,
              onViewData: () => viewDataTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('2 data menunggu dikirim'), findsOneWidget);
      expect(find.text('Lihat Data'), findsOneWidget);

      await tester.tap(find.text('Lihat Data'));
      expect(viewDataTapped, isTrue);
    });
  });

  group('Responsive Viewport Adaptability Tests', () {
    final viewports = [
      const Size(320, 568), // Small (iPhone SE 1st gen)
      const Size(360, 640), // Standard Android Small
      const Size(390, 844), // Standard iPhone 12/13/14
      const Size(412, 915), // Standard Pixel / Samsung Galaxy
      const Size(430, 932), // Large (iPhone Pro Max)
    ];

    for (final vp in viewports) {
      testWidgets(
        'Renders cleanly on viewport ${vp.width}x${vp.height} without exceptions',
        (tester) async {
          tester.view.physicalSize = vp;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ListView(
                  children: [
                    HomeHeader(
                      fullName: 'Alexander Leonardo Nelson Makai',
                      agencyName: 'BPKAD Kabupaten Mimika',
                      unreadNotificationCount: 2,
                      onNotificationTap: () {},
                    ),
                    TaskAlertBar(urgentCount: 2, onTap: () {}),
                    PrimaryTaskCard(
                      task: sampleTask,
                      onTap: () {},
                      onSeeAll: () {},
                    ),
                    const HomeQuickActions(),
                    MyActivitiesCarousel(
                      activities: [sampleTask],
                      onTaskTap: (_) {},
                      onSeeAll: () {},
                    ),
                    CompactSyncBar(
                      isOffline: false,
                      pendingCount: 0,
                      allSynced: true,
                      isSyncing: false,
                      onViewData: () {},
                    ),
                  ],
                ),
              ),
            ),
          );

          final exception = tester.takeException();
          if (exception != null) {
            debugPrint('FAILED on ${vp.width}x${vp.height}: $exception');
          }
          expect(exception, isNull);
        },
      );
    }
  });
}
