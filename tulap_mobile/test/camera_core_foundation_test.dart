import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/core/geo/fast_location_service.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/capture_geotagged_photo.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/get_task_photo_previews.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/validate_location_integrity.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/controllers/geotag_camera_controller.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_bottom_bar.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_focus_indicator.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_grid_overlay.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_mode_selector.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_top_control_bar.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_zoom_controls.dart';

// Fake UseCases untuk Pengujian Terisolasi
class FakeValidateLocationIntegrity implements ValidateLocationIntegrity {
  @override
  Future<Either<Failure, LocationIntegrityCheckResult>> call({
    dynamic position,
  }) async {
    return const Right(
      LocationIntegrityCheckResult(
        status: LocationIntegrityStatus.valid,
        latitude: -4.5468,
        longitude: 136.8837,
        accuracyMeters: 8.5,
      ),
    );
  }
}

class FakeCaptureGeotaggedPhoto implements CaptureGeotaggedPhoto {
  @override
  Future<Either<Failure, GeotagPhotoEntity>> call({
    required String taskId,
    String? caption,
  }) async {
    return Right(
      GeotagPhotoEntity(
        id: 'photo-core-1',
        taskId: taskId,
        localFilePath: 'dummy_path.jpg',
        latitude: -4.5468,
        longitude: 136.8837,
        gpsAccuracyMeters: 8.5,
        plusCode: '6P28MMMM+XX',
        serverTimestamp: DateTime(2026, 8, 26, 11, 0),
        integrityHash: 'hash123',
        finalHash: 'hash123',
        shortEvidenceId: 'TL-20260826-0001',
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
      ),
    );
  }
}

class FakeGetTaskPhotoPreviews implements GetTaskPhotoPreviews {
  @override
  Future<Either<Failure, List<GeotagPhotoEntity>>> call(String taskId) async {
    return const Right([]);
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Phase 1: Camera Core Controller Unit Tests', () {
    late GeotagCameraController controller;

    setUp(() {
      controller = GeotagCameraController(
        validateLocationIntegrity: FakeValidateLocationIntegrity(),
        captureGeotaggedPhoto: FakeCaptureGeotaggedPhoto(),
        getTaskPhotoPreviews: FakeGetTaskPhotoPreviews(),
        taskId: 'task-test-01',
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial State: Starts in Photo mode with default controls', () {
      final state = controller.state;
      expect(state.cameraMode, equals(CameraCaptureMode.photo));
      expect(state.isRecordingVideo, isFalse);
      expect(state.recordingDuration, equals(Duration.zero));
      expect(state.zoomLevel, equals(1.0));
      expect(state.flashMode, equals(FlashMode.off));
      expect(state.isGridEnabled, isFalse);
      expect(state.isSwitchingCamera, isFalse);
    });

    test('Mode Switching: Switches between Photo and Video modes', () {
      controller.setCameraMode(CameraCaptureMode.video);
      expect(controller.state.cameraMode, equals(CameraCaptureMode.video));

      controller.setCameraMode(CameraCaptureMode.photo);
      expect(controller.state.cameraMode, equals(CameraCaptureMode.photo));
    });

    test('Grid Toggle: Toggles 3x3 composition grid on and off', () {
      expect(controller.state.isGridEnabled, isFalse);
      controller.toggleGrid();
      expect(controller.state.isGridEnabled, isTrue);
      controller.toggleGrid();
      expect(controller.state.isGridEnabled, isFalse);
    });

    test('Zoom Controls: Updates zoom bounds and clamps levels', () async {
      controller.updateZoomBounds(minZoom: 0.5, maxZoom: 5.0);
      expect(controller.state.minZoomLevel, equals(0.5));
      expect(controller.state.maxZoomLevel, equals(5.0));

      await controller.setZoomLevel(3.5, null);
      expect(controller.state.zoomLevel, equals(3.5));

      // Clamp ke batas maksimum
      await controller.setZoomLevel(10.0, null);
      expect(controller.state.zoomLevel, equals(5.0));

      // Clamp ke batas minimum
      await controller.setZoomLevel(0.1, null);
      expect(controller.state.zoomLevel, equals(0.5));
    });

    test('Flash Mode Cycling: Cycles Off -> Auto -> Always -> Torch -> Off', () async {
      controller.updateFlashSupport(isSupported: true);

      // Start at Off
      expect(controller.state.flashMode, equals(FlashMode.off));

      // Off -> Auto
      await controller.cycleFlashMode(null, CameraLensDirection.back);
      expect(controller.state.flashMode, equals(FlashMode.auto));

      // Auto -> Always
      await controller.cycleFlashMode(null, CameraLensDirection.back);
      expect(controller.state.flashMode, equals(FlashMode.always));

      // Always -> Torch
      await controller.cycleFlashMode(null, CameraLensDirection.back);
      expect(controller.state.flashMode, equals(FlashMode.torch));

      // Torch -> Off
      await controller.cycleFlashMode(null, CameraLensDirection.back);
      expect(controller.state.flashMode, equals(FlashMode.off));
    });

    test('Flash Unsupported (Front Camera): Disables flash gracefully', () async {
      controller.updateFlashSupport(isSupported: false);
      expect(controller.state.isFlashSupported, isFalse);

      // Tapping cycle flash does not change mode
      await controller.cycleFlashMode(null, CameraLensDirection.front);
      expect(controller.state.flashMode, equals(FlashMode.off));
    });

    test('Tap to Focus: Activates focus indicator point and timer', () async {
      const tapOffset = Offset(150, 300);
      const previewSize = Size(360, 640);

      await controller.handleTapToFocus(
        localOffset: tapOffset,
        previewSize: previewSize,
        cameraController: null,
      );

      expect(controller.state.focusPoint, equals(tapOffset));
      expect(controller.state.isFocusIndicatorVisible, isTrue);
    });

    test('Capture Screen Flash: Triggers 100ms white screen flash feedback', () {
      controller.triggerCaptureFlash();
      expect(controller.state.isFlashAnimationActive, isTrue);
    });
  });

  group('Phase 1: Camera Core UI Widget Tests', () {
    testWidgets('CameraTopControlBar: Renders all controls and responds to taps', (tester) async {
      bool controlPanelToggled = false;
      bool flashTapped = false;
      bool noteTapped = false;
      bool locationTapped = false;
      bool timerTapped = false;
      bool settingsTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraTopControlBar(
              flashMode: FlashMode.auto,
              isFlashSupported: true,
              isSwitchingCamera: false,
              locationStatus: LocationIntegrityStatus.valid,
              locationTier: LocationTier.verified,
              accuracyMeters: 8.5,
              onToggleControlPanel: () => controlPanelToggled = true,
              onCycleFlash: () => flashTapped = true,
              onAddText: () => noteTapped = true,
              onLocationTap: () => locationTapped = true,
              onCycleTimer: () => timerTapped = true,
              onOpenSettings: () => settingsTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.motion_photos_on_outlined), findsOneWidget);
      expect(find.byIcon(Icons.flash_auto_rounded), findsOneWidget);
      expect(find.byIcon(Icons.note_add_outlined), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.motion_photos_on_outlined));
      expect(controlPanelToggled, isTrue);

      await tester.tap(find.byIcon(Icons.flash_auto_rounded));
      expect(flashTapped, isTrue);

      await tester.tap(find.byIcon(Icons.note_add_outlined));
      expect(noteTapped, isTrue);

      await tester.tap(find.byIcon(Icons.location_on_outlined));
      expect(locationTapped, isTrue);

      await tester.tap(find.byIcon(Icons.timer_outlined));
      expect(timerTapped, isTrue);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      expect(settingsTapped, isTrue);
    });

    testWidgets('CameraZoomControls: Renders 1x and 2x bubbles and switches zoom', (tester) async {
      double selectedZoom = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraZoomControls(
              currentZoom: 1.0,
              minZoom: 1.0,
              maxZoom: 4.0,
              onZoomChanged: (z) => selectedZoom = z,
            ),
          ),
        ),
      );

      expect(find.text('1x'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);

      await tester.tap(find.text('2x'));
      expect(selectedZoom, equals(2.0));
    });

    testWidgets('CameraModeSelector: Renders FOTO and VIDEO and highlights active mode', (tester) async {
      CameraCaptureMode activeMode = CameraCaptureMode.photo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraModeSelector(
              selectedMode: activeMode,
              isRecording: false,
              onModeChanged: (m) => activeMode = m,
            ),
          ),
        ),
      );

      expect(find.text('FOTO'), findsOneWidget);
      expect(find.text('VIDEO'), findsOneWidget);

      await tester.tap(find.text('VIDEO'));
      expect(activeMode, equals(CameraCaptureMode.video));
    });

    testWidgets('CameraBottomBar: Renders Photo mode shutter with Tulap Blue accent', (tester) async {
      bool capturePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraBottomBar(
              state: GeotagCameraViewState(
                cameraMode: CameraCaptureMode.photo,
                locationStatus: LocationIntegrityStatus.valid,
                accuracyMeters: 10.0,
                currentTime: DateTime(2026, 8, 26),
              ),
              onCapture: () => capturePressed = true,
              onStartRecording: () {},
              onStopRecording: () {},
              onFlipCamera: () {},
              onLowAccuracyTap: () {},
              taskPhotos: const [],
            ),
          ),
        ),
      );

      // Shutter capture tombol tersedia
      expect(find.bySemanticsLabel('Ambil foto bukti'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Ambil foto bukti'));
      expect(capturePressed, isTrue);
    });

    testWidgets('CameraBottomBar: Renders Video mode record and stop states', (tester) async {
      bool recordStarted = false;
      bool recordStopped = false;

      // 1. Video Mode Idle (Start Record)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraBottomBar(
              state: GeotagCameraViewState(
                cameraMode: CameraCaptureMode.video,
                isRecordingVideo: false,
                currentTime: DateTime(2026, 8, 26),
              ),
              onCapture: () {},
              onStartRecording: () => recordStarted = true,
              onStopRecording: () => recordStopped = true,
              onFlipCamera: () {},
              onLowAccuracyTap: () {},
              taskPhotos: const [],
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Mulai rekam video'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Mulai rekam video'));
      expect(recordStarted, isTrue);

      // 2. Video Mode Recording (Stop Record)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraBottomBar(
              state: GeotagCameraViewState(
                cameraMode: CameraCaptureMode.video,
                isRecordingVideo: true,
                currentTime: DateTime(2026, 8, 26),
              ),
              onCapture: () {},
              onStartRecording: () {},
              onStopRecording: () => recordStopped = true,
              onFlipCamera: () {},
              onLowAccuracyTap: () {},
              taskPhotos: const [],
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Hentikan rekaman video'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Hentikan rekaman video'));
      expect(recordStopped, isTrue);
    });

    testWidgets('CameraGridOverlay: Renders 3x3 grid when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CameraGridOverlay(visible: true),
          ),
        ),
      );

      expect(find.byType(CameraGridOverlay), findsOneWidget);
    });

    testWidgets('CameraFocusIndicator: Renders animated focus ring at tap location', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CameraFocusIndicator(
                  position: Offset(100, 200),
                  visible: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CameraFocusIndicator), findsOneWidget);
    });
  });
}
