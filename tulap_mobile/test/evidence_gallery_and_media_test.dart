import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tulap_mobile/core/map/map_launcher_service.dart';
import 'package:tulap_mobile/core/media/media_share_service.dart';
import 'package:tulap_mobile/core/media/media_thumbnail_service.dart';
import 'package:tulap_mobile/features/evidence_gallery/domain/usecases/delete_evidence.dart';
import 'package:tulap_mobile/features/evidence_gallery/domain/usecases/get_activity_evidence.dart';
import 'package:tulap_mobile/features/evidence_gallery/domain/usecases/share_evidence.dart';
import 'package:tulap_mobile/features/evidence_gallery/presentation/pages/activity_gallery_page.dart';
import 'package:tulap_mobile/features/evidence_gallery/presentation/pages/evidence_viewer_page.dart';
import 'package:tulap_mobile/features/evidence_gallery/presentation/widgets/evidence_photo_viewer_widget.dart';
import 'package:tulap_mobile/features/evidence_gallery/presentation/widgets/evidence_video_player_widget.dart';
import 'package:tulap_mobile/features/evidence_verification/presentation/pages/evidence_detail_page.dart';
import 'package:tulap_mobile/features/geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import 'package:tulap_mobile/features/geotag_camera/data/models/geotag_photo_model.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';
import 'package:tulap_mobile/features/sync_queue/data/datasources/sync_local_datasource.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';

class FakeGeotagCameraLocalDataSource extends Fake
    implements GeotagCameraLocalDataSource {
  final List<GeotagPhotoModel> photos = [];

  @override
  Future<List<GeotagPhotoModel>> getPhotosByTask(String taskId) async {
    return photos.where((p) => p.taskId == taskId).toList()
      ..sort((a, b) => b.serverTimestamp.compareTo(a.serverTimestamp));
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    photos.removeWhere((p) => p.id == photoId);
  }
}

class FakeSyncLocalDataSource extends Fake implements SyncLocalDataSource {
  final List<String> deletedEntityIds = [];

  @override
  Future<int> deleteRecordsByEntityLocalId(String entityLocalId) async {
    deletedEntityIds.add(entityLocalId);
    return 1;
  }
}

class FakeMediaShareService extends Fake implements MediaShareService {
  GeotagPhotoEntity? lastSharedEvidence;
  String? lastSharedTaskName;

  @override
  Future<bool> shareEvidence({
    required GeotagPhotoEntity evidence,
    String? taskName,
  }) async {
    lastSharedEvidence = evidence;
    lastSharedTaskName = taskName;
    return true;
  }
}

class FakeMapLauncherService extends Fake implements MapLauncherService {
  double? lastLatitude;
  double? lastLongitude;

  @override
  Future<bool> openGoogleMaps({
    required double latitude,
    required double longitude,
  }) async {
    lastLatitude = latitude;
    lastLongitude = longitude;
    return true;
  }
}

Widget _wrapTestWidget(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('id', 'ID'),
      Locale('en', 'US'),
    ],
    locale: const Locale('id', 'ID'),
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGeotagCameraLocalDataSource fakeCameraDataSource;
  late FakeSyncLocalDataSource fakeSyncDataSource;
  late FakeMediaShareService fakeShareService;
  late FakeMapLauncherService fakeMapService;
  late MediaThumbnailService thumbnailService;
  late GetActivityEvidence getActivityEvidence;
  late DeleteEvidence deleteEvidence;
  late ShareEvidence shareEvidence;

  final sl = GetIt.instance;

  final samplePhoto = GeotagPhotoModel(
    id: 'photo-1',
    taskId: 'task-100',
    localFilePath: 'assets/images/placeholder.jpg',
    latitude: -4.5403,
    longitude: 136.8764,
    gpsAccuracyMeters: 12.0,
    address: 'Jl. Cenderawasih, Mimika, Papua Tengah',
    plusCode: '6P28+4X Mimika',
    integrityHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    isMockLocationDetected: false,
    isRootedDeviceDetected: false,
    serverTimestamp: DateTime(2026, 8, 26, 11, 13),
    caption: 'Pemeriksaan fisik kendaraan dinas',
    mediaType: 'PHOTO',
  );

  final sampleVideo = GeotagPhotoModel(
    id: 'video-1',
    taskId: 'task-100',
    localFilePath: 'assets/videos/sample.mp4',
    latitude: -4.5410,
    longitude: 136.8770,
    gpsAccuracyMeters: 8.5,
    address: 'Kantor Bupati Mimika, Papua Tengah',
    plusCode: '6P28+5Y Mimika',
    integrityHash: 'a1b2c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789abcdef0',
    isMockLocationDetected: false,
    isRootedDeviceDetected: false,
    serverTimestamp: DateTime(2026, 8, 26, 11, 20),
    caption: 'Rekaman video inspeksi kendaraan',
    mediaType: 'VIDEO',
    durationSeconds: 24,
  );

  final sampleTask = TaskEntity(
    id: 'task-100',
    taskCode: 'TSK-001',
    taskName: 'Monitoring Kendaraan Dinas',
    destination: 'Mimika, Papua Tengah',
    budgetAmount: 1500000.0,
    status: TaskStatusEntity.ongoing,
    assigneeId: 'usr-1',
    assigneeName: 'Petugas Lapangan',
    checklistItems: const [],
    geotagPhotoCount: 2,
    expenseNoteCount: 0,
    createdAt: DateTime(2026, 8, 26, 9, 0),
    startDate: DateTime(2026, 8, 26, 10, 0),
    endDate: DateTime(2026, 8, 26, 17, 0),
  );

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    sl.reset();

    fakeCameraDataSource = FakeGeotagCameraLocalDataSource();
    fakeSyncDataSource = FakeSyncLocalDataSource();
    fakeShareService = FakeMediaShareService();
    fakeMapService = FakeMapLauncherService();
    thumbnailService = MediaThumbnailService();

    getActivityEvidence = GetActivityEvidence(fakeCameraDataSource);
    deleteEvidence = DeleteEvidence(
      cameraLocalDataSource: fakeCameraDataSource,
      syncLocalDataSource: fakeSyncDataSource,
    );
    shareEvidence = ShareEvidence(fakeShareService);

    sl.registerSingleton<GeotagCameraLocalDataSource>(fakeCameraDataSource);
    sl.registerSingleton<SyncLocalDataSource>(fakeSyncDataSource);
    sl.registerSingleton<MediaShareService>(fakeShareService);
    sl.registerSingleton<MapLauncherService>(fakeMapService);
    sl.registerSingleton<MediaThumbnailService>(thumbnailService);
    sl.registerSingleton<GetActivityEvidence>(getActivityEvidence);
    sl.registerSingleton<DeleteEvidence>(deleteEvidence);
    sl.registerSingleton<ShareEvidence>(shareEvidence);

    fakeCameraDataSource.photos.addAll([samplePhoto, sampleVideo]);
  });

  tearDown(() {
    sl.reset();
  });

  group('Phase 5: Domain & Services Use Cases Tests', () {
    test('GetActivityEvidence retrieves evidence scoped to taskId in newest-first order', () async {
      final result = await getActivityEvidence('task-100');
      expect(result.isRight(), isTrue);

      final list = result.getOrElse(() => []);
      expect(list.length, equals(2));
      // Newest first: sampleVideo (11:20) should precede samplePhoto (11:13)
      expect(list[0].id, equals('video-1'));
      expect(list[0].isVideo, isTrue);
      expect(list[1].id, equals('photo-1'));
      expect(list[1].isPhoto, isTrue);
    });

    test('GetActivityEvidence never mixes evidence from another taskId', () async {
      final otherPhoto = GeotagPhotoModel(
        id: 'photo-99',
        taskId: 'task-OTHER',
        localFilePath: 'assets/images/other.jpg',
        latitude: -6.2088,
        longitude: 106.8456,
        gpsAccuracyMeters: 5.0,
        plusCode: '7P59+8Z Jakarta',
        integrityHash: 'b2c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789abcdef01',
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
        serverTimestamp: DateTime.now(),
        mediaType: 'PHOTO',
      );
      fakeCameraDataSource.photos.add(otherPhoto);

      final result = await getActivityEvidence('task-100');
      final list = result.getOrElse(() => []);
      expect(list.any((p) => p.taskId != 'task-100'), isFalse);
    });

    test('DeleteEvidence safely removes database record and outbox sync item', () async {
      final result = await deleteEvidence(evidenceId: 'photo-1');
      expect(result.isRight(), isTrue);

      expect(fakeCameraDataSource.photos.any((p) => p.id == 'photo-1'), isFalse);
      expect(fakeSyncDataSource.deletedEntityIds.contains('photo-1'), isTrue);
    });

    test('ShareEvidence delegates to MediaShareService with descriptive metadata', () async {
      final result = await shareEvidence(
        evidence: samplePhoto,
        taskName: 'Monitoring Kendaraan Dinas',
      );
      expect(result.isRight(), isTrue);
      expect(fakeShareService.lastSharedEvidence?.id, equals('photo-1'));
      expect(fakeShareService.lastSharedTaskName, equals('Monitoring Kendaraan Dinas'));
    });

    test('MapLauncherService constructs correct coordinates search URL format', () {
      final realMapService = MapLauncherService();
      final url = realMapService.buildGoogleMapsUrl(
        latitude: -4.5403,
        longitude: 136.8764,
      );
      expect(url, equals('https://www.google.com/maps/search/?api=1&query=-4.5403,136.8764'));
    });
  });

  group('Phase 5: Presentation Widgets Tests', () {
    testWidgets('EvidencePhotoViewerWidget mounts InteractiveViewer with zoom range', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          Scaffold(
            body: EvidencePhotoViewerWidget(
              evidence: samplePhoto,
              onToggleControls: () {},
            ),
          ),
        ),
      );

      expect(find.byType(InteractiveViewer), findsOneWidget);
      final interactiveViewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      expect(interactiveViewer.minScale, equals(1.0));
      expect(interactiveViewer.maxScale, equals(4.0));
    });

    testWidgets('EvidenceVideoPlayerWidget renders duration and action overlays', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          Scaffold(
            body: EvidenceVideoPlayerWidget(
              evidence: sampleVideo,
              isActive: true,
              onToggleControls: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('00:24'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
    });

    testWidgets('EvidenceViewerPage renders top bar indicator and action buttons', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          EvidenceViewerPage(
            initialEvidenceList: [sampleVideo, samplePhoto],
            initialIndex: 0,
            taskId: 'task-100',
            task: sampleTask,
          ),
        ),
      );

      // Top Bar
      expect(find.text('Pratinjau'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      // Bottom Bar Action Buttons
      expect(find.text('Detail'), findsOneWidget);
      expect(find.text('Lokasi'), findsOneWidget);
      expect(find.text('Bagikan'), findsOneWidget);
    });

    testWidgets('EvidenceViewerPage shows safe deletion confirmation and deletes on confirm', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          EvidenceViewerPage(
            initialEvidenceList: [sampleVideo, samplePhoto],
            initialIndex: 0,
            taskId: 'task-100',
            task: sampleTask,
          ),
        ),
      );

      // Open more menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Hapus Bukti
      await tester.tap(find.text('Hapus Bukti'));
      await tester.pumpAndSettle();

      // Verify Dialog
      expect(find.text('Hapus Bukti?'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      // Evidence list now has 1 item
      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('EvidenceViewerPage renders clean empty state when no evidence exists', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          const EvidenceViewerPage(
            initialEvidenceList: [],
            initialIndex: 0,
            taskId: 'task-100',
          ),
        ),
      );

      expect(find.text('Belum Ada Dokumentasi'), findsOneWidget);
      expect(find.text('Ambil Dokumentasi'), findsOneWidget);
    });

    testWidgets('ActivityGalleryPage renders filter chips and handles filter change', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          ActivityGalleryPage(
            taskId: 'task-100',
            task: sampleTask,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Galeri Dokumentasi'), findsOneWidget);
      expect(find.text('Semua (2)'), findsOneWidget);
      expect(find.text('Foto (1)'), findsOneWidget);
      expect(find.text('Video (1)'), findsOneWidget);

      // Tap filter Foto
      await tester.tap(find.text('Foto (1)'));
      await tester.pumpAndSettle();

      // Grid items should now display 1 item
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('EvidenceDetailPage renders Section 23 structured information & maps action', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          EvidenceDetailPage(
            photo: samplePhoto,
            task: sampleTask,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header & Title
      expect(find.text('Detail Bukti'), findsOneWidget);

      // Sections
      expect(find.text('INFORMASI KEGIATAN'), findsOneWidget);
      expect(find.text('LOKASI'), findsOneWidget);
      expect(find.text('BUKTI'), findsOneWidget);
      expect(find.text('PETUGAS'), findsOneWidget);
      expect(find.text('KETERANGAN'), findsOneWidget);
      expect(find.text('Informasi Teknis'), findsOneWidget);

      // Google Maps button
      expect(find.text('Buka di Google Maps'), findsOneWidget);

      // Tapping Google Maps invokes MapLauncherService with stored coordinates
      await tester.scrollUntilVisible(find.text('Buka di Google Maps'), 50.0);
      await tester.tap(find.text('Buka di Google Maps'));
      await tester.pump();
      expect(fakeMapService.lastLatitude, equals(-4.5403));
      expect(fakeMapService.lastLongitude, equals(136.8764));
    });
  });
}
