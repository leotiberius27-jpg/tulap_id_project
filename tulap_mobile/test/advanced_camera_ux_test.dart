import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/camera/camera_capability_service.dart';
import 'package:tulap_mobile/core/camera/camera_level_sensor_service.dart';
import 'package:tulap_mobile/core/camera/file_naming_service.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/core/geo/fast_location_service.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/camera_preferences_entity.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/capture_geotagged_photo.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/validate_location_integrity.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/controllers/geotag_camera_controller.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/pages/advanced_camera_settings_page.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_add_text_sheet.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_control_panel.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_level_overlay.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_rename_sheet.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_timer_countdown_overlay.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_top_control_bar.dart';

// Fake implementations for unit testing
class FakeValidateLocationIntegrity implements ValidateLocationIntegrity {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, LocationIntegrityCheckResult>> call({
    dynamic position,
  }) async {
    return const Right(
      LocationIntegrityCheckResult(
        status: LocationIntegrityStatus.valid,
        latitude: -6.2088,
        longitude: 106.8456,
        accuracyMeters: 5.0,
      ),
    );
  }
}

class FakeCaptureGeotaggedPhoto implements CaptureGeotaggedPhoto {
  String? lastCapturedCaption;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, GeotagPhotoEntity>> call({
    required String taskId,
    String? caption,
  }) async {
    lastCapturedCaption = caption;
    return Right(
      GeotagPhotoEntity(
        id: 'TL-20260826-0001',
        taskId: taskId,
        localFilePath: 'test_evidence.jpg',
        latitude: -6.2088,
        longitude: 106.8456,
        gpsAccuracyMeters: 4.5,
        plusCode: '6P587R8W+XX',
        serverTimestamp: DateTime.now(),
        integrityHash:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
        address: 'Jl. Merdeka No. 1, Jakarta Pusat',
        caption: caption,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4: CameraPreferencesEntity & Serialization', () {
    test('Default values follow safe specifications', () {
      const prefs = CameraPreferencesEntity();
      expect(prefs.aspectRatio, CameraAspectRatio.ratioFull);
      expect(prefs.gridEnabled, false);
      expect(prefs.timerSeconds, 0);
      expect(prefs.focusGuideEnabled, true);
      expect(prefs.mirrorFrontCamera, true);
      expect(prefs.shutterSoundPreference, ShutterSoundPreference.system);
      expect(prefs.whiteBalance, CameraWhiteBalanceMode.auto);
      expect(prefs.levelEnabled, false);
      expect(prefs.videoAudioEnabled, true);
      expect(prefs.photoQuality, PhotoQualityPreference.standard);
      expect(prefs.videoQuality, VideoQualityPreference.q1080p);
      expect(prefs.fileNamingMode, FileNamingMode.automatic);
      expect(prefs.saveOriginalMedia, true);
      expect(prefs.volumeButtonShutter, true);
      expect(prefs.customCaption, isNull);
    });

    test('toMap and fromMap preserves all fields faithfully', () {
      const original = CameraPreferencesEntity(
        aspectRatio: CameraAspectRatio.ratio16x9,
        gridEnabled: true,
        timerSeconds: 5,
        focusGuideEnabled: false,
        mirrorFrontCamera: false,
        shutterSoundPreference: ShutterSoundPreference.disabled,
        whiteBalance: CameraWhiteBalanceMode.daylight,
        levelEnabled: true,
        videoAudioEnabled: false,
        photoQuality: PhotoQualityPreference.high,
        videoQuality: VideoQualityPreference.q720p,
        fileNamingMode: FileNamingMode.custom,
        customFilePrefix: 'Survei_Jalan',
        saveOriginalMedia: true,
        volumeButtonShutter: false,
        customCaption: 'Pemeriksaan tiang listrik',
      );

      final map = original.toMap();
      final reconstructed = CameraPreferencesEntity.fromMap(map);

      expect(reconstructed.aspectRatio, CameraAspectRatio.ratio16x9);
      expect(reconstructed.gridEnabled, true);
      expect(reconstructed.timerSeconds, 5);
      expect(reconstructed.focusGuideEnabled, false);
      expect(reconstructed.mirrorFrontCamera, false);
      expect(reconstructed.shutterSoundPreference, ShutterSoundPreference.disabled);
      expect(reconstructed.whiteBalance, CameraWhiteBalanceMode.daylight);
      expect(reconstructed.levelEnabled, true);
      expect(reconstructed.videoAudioEnabled, false);
      expect(reconstructed.photoQuality, PhotoQualityPreference.high);
      expect(reconstructed.videoQuality, VideoQualityPreference.q720p);
      expect(reconstructed.fileNamingMode, FileNamingMode.custom);
      expect(reconstructed.customFilePrefix, 'Survei_Jalan');
      expect(reconstructed.volumeButtonShutter, false);
      expect(reconstructed.customCaption, 'Pemeriksaan tiang listrik');
    });

    test('copyWith updates specified fields only', () {
      const prefs = CameraPreferencesEntity();
      final updated = prefs.copyWith(
        aspectRatio: CameraAspectRatio.ratioFull,
        timerSeconds: 10,
        gridEnabled: true,
      );

      expect(updated.aspectRatio, CameraAspectRatio.ratioFull);
      expect(updated.timerSeconds, 10);
      expect(updated.gridEnabled, true);
      expect(updated.focusGuideEnabled, true); // Unchanged
    });
  });

  group('Phase 4: FileNamingService', () {
    final service = FileNamingService();

    test('Sanitizes illegal characters and whitespace properly', () {
      expect(service.sanitize('Kegiatan / Patroli : Malam * 2026?'), 'Kegiatan_Patroli_Malam_2026');
      expect(service.sanitize('Monitoring <Pipa> | Sektor A & B'), 'Monitoring_Pipa_Sektor_A_B');
      expect(service.sanitize('   ___Nama   Tugas___  '), 'Nama_Tugas');
      expect(service.sanitize(''), 'Bukti_Lapangan');
    });

    test('Generates automatic filename with activity, date, time, and sequence', () {
      final timestamp = DateTime(2026, 8, 26, 14, 30, 45);
      final filename = service.generateFilename(
        mode: FileNamingMode.automatic,
        taskName: 'Survei Jembatan',
        timestamp: timestamp,
        isVideo: false,
        sequence: 1,
      );

      expect(filename, 'Survei_Jembatan_20260826_143045_001.jpg');
    });

    test('Generates custom filename with custom prefix, date, and sequence', () {
      final timestamp = DateTime(2026, 8, 26, 14, 30, 45);
      final filename = service.generateFilename(
        mode: FileNamingMode.custom,
        taskName: 'Survei Jembatan',
        customPrefix: 'Inspeksi Fisik',
        timestamp: timestamp,
        isVideo: true,
        sequence: 2,
      );

      expect(filename, 'Inspeksi_Fisik_20260826_002.mp4');
    });
  });

  group('Phase 4: CameraCapabilityService', () {
    test('Evaluates empty camera description list safely', () async {
      final service = CameraCapabilityService();
      final capabilities = await service.evaluate(availableCameras: []);

      expect(capabilities.hasFrontCamera, false);
      expect(capabilities.hasBackCamera, false);
      expect(capabilities.supportsAudio, true);
    });

    test('Detects front and back camera presence', () async {
      final service = CameraCapabilityService();
      final cameras = [
        const CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
        const CameraDescription(
          name: '1',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        ),
      ];

      final capabilities = await service.evaluate(availableCameras: cameras);
      expect(capabilities.hasBackCamera, true);
      expect(capabilities.hasFrontCamera, true);
    });
  });

  group('Phase 4: GeotagCameraController Advanced Controls Logic', () {
    late GeotagCameraController controller;
    late FakeValidateLocationIntegrity fakeValidate;
    late FakeCaptureGeotaggedPhoto fakeCapture;

    setUp(() {
      fakeValidate = FakeValidateLocationIntegrity();
      fakeCapture = FakeCaptureGeotaggedPhoto();
      controller = GeotagCameraController(
        validateLocationIntegrity: fakeValidate,
        captureGeotaggedPhoto: fakeCapture,
        taskId: 'TASK-101',
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Control panel toggles open and close cleanly', () {
      expect(controller.state.isControlPanelOpen, false);
      controller.toggleControlPanel();
      expect(controller.state.isControlPanelOpen, true);
      controller.closeControlPanel();
      expect(controller.state.isControlPanelOpen, false);
    });

    test('Aspect ratio cycles Full -> 4:3 -> 16:9 -> Full', () {
      expect(controller.state.cameraPreferences.aspectRatio, CameraAspectRatio.ratioFull);
      controller.cycleAspectRatio();
      expect(controller.state.cameraPreferences.aspectRatio, CameraAspectRatio.ratio4x3);
      controller.cycleAspectRatio();
      expect(controller.state.cameraPreferences.aspectRatio, CameraAspectRatio.ratio16x9);
      controller.cycleAspectRatio();
      expect(controller.state.cameraPreferences.aspectRatio, CameraAspectRatio.ratioFull);
    });

    test('Grid toggle updates state and preferences', () {
      expect(controller.state.isGridEnabled, false);
      controller.toggleGrid();
      expect(controller.state.isGridEnabled, true);
      expect(controller.state.cameraPreferences.gridEnabled, true);
      controller.toggleGrid();
      expect(controller.state.isGridEnabled, false);
    });

    test('Timer cycles Off -> 3s -> 5s -> 10s -> Off', () {
      expect(controller.state.cameraPreferences.timerSeconds, 0);
      controller.cycleTimer();
      expect(controller.state.cameraPreferences.timerSeconds, 3);
      controller.cycleTimer();
      expect(controller.state.cameraPreferences.timerSeconds, 5);
      controller.cycleTimer();
      expect(controller.state.cameraPreferences.timerSeconds, 10);
      controller.cycleTimer();
      expect(controller.state.cameraPreferences.timerSeconds, 0);
    });

    test('Shutter sound cycles System -> Enabled -> Disabled -> System', () {
      expect(controller.state.cameraPreferences.shutterSoundPreference, ShutterSoundPreference.system);
      controller.cycleShutterSound();
      expect(controller.state.cameraPreferences.shutterSoundPreference, ShutterSoundPreference.enabled);
      controller.cycleShutterSound();
      expect(controller.state.cameraPreferences.shutterSoundPreference, ShutterSoundPreference.disabled);
      controller.cycleShutterSound();
      expect(controller.state.cameraPreferences.shutterSoundPreference, ShutterSoundPreference.system);
    });

    test('Mirror front camera toggle updates preferences', () {
      expect(controller.state.cameraPreferences.mirrorFrontCamera, true);
      controller.toggleMirrorFrontCamera();
      expect(controller.state.cameraPreferences.mirrorFrontCamera, false);
    });

    test('Video audio toggle updates preferences', () {
      expect(controller.state.cameraPreferences.videoAudioEnabled, true);
      controller.toggleVideoAudio();
      expect(controller.state.cameraPreferences.videoAudioEnabled, false);
    });

    test('Custom caption is passed through to photo capture', () async {
      controller.setCustomCaption('Pemeriksaan fasilitas lapangan');
      expect(controller.state.caption, 'Pemeriksaan fasilitas lapangan');

      await controller.onCaptureButtonPressed();
      expect(fakeCapture.lastCapturedCaption, 'Pemeriksaan fasilitas lapangan');
    });

    test('Timer countdown cancel stops active countdown', () {
      controller.setTimerSeconds(5);
      controller.onCaptureButtonPressed();

      expect(controller.state.isCountdownActive, true);
      expect(controller.state.remainingTimerSeconds, 5);

      controller.cancelTimerCountdown();
      expect(controller.state.isCountdownActive, false);
      expect(controller.state.remainingTimerSeconds, 0);
    });

    test('Reset camera preferences restores all default values', () async {
      controller.setAspectRatio(CameraAspectRatio.ratio16x9);
      controller.toggleGrid();
      controller.setTimerSeconds(10);
      controller.setCustomCaption('Catatan');

      await controller.resetCameraPreferences();

      expect(controller.state.cameraPreferences.aspectRatio, CameraAspectRatio.ratioFull);
      expect(controller.state.cameraPreferences.gridEnabled, false);
      expect(controller.state.cameraPreferences.timerSeconds, 0);
      expect(controller.state.caption, isNull);
    });
  });

  group('Phase 4: Widget Integration Tests', () {
    testWidgets('CameraControlPanel displays 4-row control grid correctly', (tester) async {
      final fakeValidate = FakeValidateLocationIntegrity();
      final fakeCapture = FakeCaptureGeotaggedPhoto();
      final controller = GeotagCameraController(
        validateLocationIntegrity: fakeValidate,
        captureGeotaggedPhoto: fakeCapture,
        taskId: 'TASK-001',
      );

      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraControlPanel(
              controller: controller,
              cameraController: null,
              currentLensDirection: CameraLensDirection.back,
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      // Verify row controls
      expect(find.text('KONTROL KAMERA'), findsOneWidget);
      expect(find.text('Rasio'), findsOneWidget);
      expect(find.text('Grid'), findsOneWidget);
      expect(find.text('Timer'), findsOneWidget);
      expect(find.text('Fokus'), findsOneWidget);
      expect(find.text('Mirror'), findsOneWidget);
      expect(find.text('Suara'), findsOneWidget);
      expect(find.text('Level'), findsOneWidget);
      expect(find.text('Teks'), findsOneWidget);
      expect(find.text('Rekam Video dengan Suara'), findsOneWidget);

      // Tap Grid control
      await tester.tap(find.text('Grid'));
      await tester.pump();
      expect(controller.state.isGridEnabled, true);

      // Tap Close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closed, true);

      controller.dispose();
    });

    testWidgets('CameraTimerCountdownOverlay renders active countdown number and handles cancel tap', (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraTimerCountdownOverlay(
              remainingSeconds: 3,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Ketuk di mana saja untuk membatalkan'), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      expect(cancelled, true);
    });

    testWidgets('CameraLevelOverlay renders level horizon line with angle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CameraLevelOverlay(
              rollDegrees: 0.0,
              isLevel: true,
              visible: true,
            ),
          ),
        ),
      );

      expect(find.text('SEJAJAR (0°)'), findsOneWidget);
    });

    testWidgets('CameraAddTextSheet allows entering and saving custom caption', (tester) async {
      String? savedText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraAddTextSheet(
              currentCaption: null,
              onSave: (val) => savedText = val,
            ),
          ),
        ),
      );

      expect(find.text('Tambahkan Keterangan'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Pemeriksaan rambu lalu lintas');
      await tester.tap(find.text('Simpan'));
      await tester.pump();

      expect(savedText, 'Pemeriksaan rambu lalu lintas');
    });

    testWidgets('CameraRenameSheet provides automatic vs custom mode and preview', (tester) async {
      FileNamingMode? savedMode;
      String? savedPrefix;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraRenameSheet(
              currentMode: FileNamingMode.automatic,
              currentPrefix: null,
              taskName: 'Survei Drainase',
              isVideo: false,
              onSave: (mode, prefix) {
                savedMode = mode;
                savedPrefix = prefix;
              },
            ),
          ),
        ),
      );

      expect(find.text('Pola Nama Berkas'), findsOneWidget);
      expect(find.text('Format Otomatis Berbasis Tugas'), findsOneWidget);
      expect(find.text('Format Kustom'), findsOneWidget);

      // Select Custom
      await tester.tap(find.text('Format Kustom'));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Inspeksi_Jalan');
      await tester.tap(find.text('Terapkan'));
      await tester.pump();

      expect(savedMode, FileNamingMode.custom);
      expect(savedPrefix, 'Inspeksi_Jalan');
    });

    testWidgets('CameraTopControlBar renders 6 professional icons and handles interactions', (tester) async {
      bool controlPanelToggled = false;
      bool flashCycled = false;
      bool addTextCalled = false;
      bool locationCalled = false;
      bool timerCalled = false;
      bool settingsOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraTopControlBar(
              isControlPanelOpen: false,
              flashMode: FlashMode.off,
              isFlashSupported: true,
              isSwitchingCamera: false,
              locationStatus: LocationIntegrityStatus.valid,
              locationTier: LocationTier.verified,
              accuracyMeters: 4.2,
              timerSeconds: 0,
              onToggleControlPanel: () => controlPanelToggled = true,
              onCycleFlash: () => flashCycled = true,
              onAddText: () => addTextCalled = true,
              onLocationTap: () => locationCalled = true,
              onCycleTimer: () => timerCalled = true,
              onOpenSettings: () => settingsOpened = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.motion_photos_on_outlined));
      expect(controlPanelToggled, true);

      await tester.tap(find.byIcon(Icons.flash_off_rounded));
      expect(flashCycled, true);

      await tester.tap(find.byIcon(Icons.note_add_outlined));
      expect(addTextCalled, true);

      await tester.tap(find.byIcon(Icons.location_on_outlined));
      expect(locationCalled, true);

      await tester.tap(find.byIcon(Icons.timer_outlined));
      expect(timerCalled, true);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      expect(settingsOpened, true);
    });

    testWidgets('AdvancedCameraSettingsPage renders grouped sections and reset dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeValidate = FakeValidateLocationIntegrity();
      final fakeCapture = FakeCaptureGeotaggedPhoto();
      final controller = GeotagCameraController(
        validateLocationIntegrity: fakeValidate,
        captureGeotaggedPhoto: fakeCapture,
        taskId: 'TASK-SETTINGS',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdvancedCameraSettingsPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan Kamera'), findsOneWidget);
      expect(find.text('KAMERA & FOTO'), findsOneWidget);
      expect(find.text('PEREKAMAN VIDEO'), findsOneWidget);
      expect(find.text('PENGAMBILAN BUKTI'), findsOneWidget);
      expect(find.text('TAMPILAN KAMERA & SENSOR'), findsOneWidget);
      expect(find.text('DOKUMENTASI STAMP TULAP.ID'), findsOneWidget);
      expect(find.text('Reset Pengaturan Kamera'), findsOneWidget);

      // Open reset dialog
      await tester.tap(find.text('Reset Pengaturan Kamera'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Pengaturan Kamera?'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      controller.dispose();
    });
  });
}
