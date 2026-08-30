import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/camera/camera_capability_service.dart';
import '../../../../core/camera/camera_level_sensor_service.dart';
import '../../../../core/camera/file_naming_service.dart';
import '../../../../core/geo/fast_location_service.dart';
import '../../../../core/geo/reverse_geocoder.dart';
import '../../domain/entities/camera_preferences_entity.dart';
import '../../domain/entities/geotag_photo_entity.dart';
import '../../domain/entities/watermark_template_entity.dart';
import '../../domain/repositories/camera_preferences_repository.dart';
import '../../domain/repositories/template_repository.dart';
import '../../domain/usecases/capture_geotagged_photo.dart';
import '../../domain/usecases/create_evidence.dart';
import '../../domain/usecases/get_task_photo_previews.dart';
import '../../domain/usecases/validate_location_integrity.dart';
import '../widgets/camera_mode_selector.dart';

/// GeotagCameraViewState
/// ----------------------------------------------------------------------
/// State UI terpadu untuk layar kamera Tulap.id (Phase 1-4):
/// - Status tier lokasi 3-level & koordinat live
/// - Mode kamera (Foto vs Video) & durasi perekaman
/// - Kontrol flash, zoom (pinch & quick zoom), grid overlay, & animasi fokus
/// - Preferensi kamera lanjutan (Rasio, Timer, Level, Mirror, Suara, Kualitas, Penamaan)
/// - Status countdown timer & live sensor level
/// ----------------------------------------------------------------------
enum CaptureViewStatus { idle, capturing, previewing, error }

class GeotagCameraViewState {
  final LocationIntegrityStatus locationStatus;
  final LocationTier locationTier;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String? address;
  final CaptureViewStatus captureStatus;
  final GeotagPhotoEntity? lastCapturedPhoto;
  final String? errorMessage;
  final bool isGpsOverrideAllowed;
  final Offset? focusPoint;
  final bool isFocusIndicatorVisible;
  final DateTime currentTime;
  final List<GeotagPhotoEntity> taskPhotos;
  final StampConfiguration stampConfig;

  // Phase 1 Camera Core Properties
  final CameraCaptureMode cameraMode;
  final bool isRecordingVideo;
  final Duration recordingDuration;
  final String? recordedVideoPath;
  final double zoomLevel;
  final double minZoomLevel;
  final double maxZoomLevel;
  final bool isGridEnabled;
  final FlashMode flashMode;
  final bool isFlashSupported;
  final bool isSwitchingCamera;
  final bool isFlashAnimationActive;

  // Phase 4 Advanced Camera UX Properties
  final CameraPreferencesEntity cameraPreferences;
  final bool isControlPanelOpen;
  final int remainingTimerSeconds;
  final double levelDegrees;
  final bool isLevel;
  final String? caption;

  const GeotagCameraViewState({
    this.locationStatus = LocationIntegrityStatus.checking,
    this.locationTier = LocationTier.none,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.address,
    this.captureStatus = CaptureViewStatus.idle,
    this.lastCapturedPhoto,
    this.errorMessage,
    this.isGpsOverrideAllowed = false,
    this.focusPoint,
    this.isFocusIndicatorVisible = false,
    required this.currentTime,
    this.taskPhotos = const [],
    this.stampConfig = const StampConfiguration(),
    this.cameraMode = CameraCaptureMode.photo,
    this.isRecordingVideo = false,
    this.recordingDuration = Duration.zero,
    this.recordedVideoPath,
    this.zoomLevel = 1.0,
    this.minZoomLevel = 1.0,
    this.maxZoomLevel = 8.0,
    this.isGridEnabled = false,
    this.flashMode = FlashMode.off,
    this.isFlashSupported = true,
    this.isSwitchingCamera = false,
    this.isFlashAnimationActive = false,
    this.cameraPreferences = const CameraPreferencesEntity(),
    this.isControlPanelOpen = false,
    this.remainingTimerSeconds = 0,
    this.levelDegrees = 0.0,
    this.isLevel = false,
    this.caption,
  });

  /// Ambang batas akurasi "GPS Akurat" untuk capture resmi (<= 15m).
  static const double gpsLockAccuracyMeters = 15.0;

  bool get isGpsLocked =>
      accuracyMeters != null && accuracyMeters! <= gpsLockAccuracyMeters;

  bool get isAcceptable => accuracyMeters != null && accuracyMeters! <= 30.0;

  bool get isCountdownActive => remainingTimerSeconds > 0;

  bool get isCaptureEnabled =>
      locationStatus == LocationIntegrityStatus.valid &&
      (isGpsLocked || isGpsOverrideAllowed) &&
      captureStatus != CaptureViewStatus.capturing &&
      !isSwitchingCamera &&
      !isCountdownActive;

  String get formattedRecordingDuration {
    final minutes = recordingDuration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = recordingDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final hours = recordingDuration.inHours > 0
        ? '${recordingDuration.inHours.toString().padLeft(2, '0')}:'
        : '';
    return '$hours$minutes:$seconds';
  }

  GeotagCameraViewState copyWith({
    LocationIntegrityStatus? locationStatus,
    LocationTier? locationTier,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? address,
    CaptureViewStatus? captureStatus,
    GeotagPhotoEntity? lastCapturedPhoto,
    String? errorMessage,
    bool? isGpsOverrideAllowed,
    Offset? focusPoint,
    bool? isFocusIndicatorVisible,
    DateTime? currentTime,
    List<GeotagPhotoEntity>? taskPhotos,
    StampConfiguration? stampConfig,
    CameraCaptureMode? cameraMode,
    bool? isRecordingVideo,
    Duration? recordingDuration,
    String? recordedVideoPath,
    double? zoomLevel,
    double? minZoomLevel,
    double? maxZoomLevel,
    bool? isGridEnabled,
    FlashMode? flashMode,
    bool? isFlashSupported,
    bool? isSwitchingCamera,
    bool? isFlashAnimationActive,
    CameraPreferencesEntity? cameraPreferences,
    bool? isControlPanelOpen,
    int? remainingTimerSeconds,
    double? levelDegrees,
    bool? isLevel,
    String? caption,
    bool clearCaption = false,
  }) {
    return GeotagCameraViewState(
      locationStatus: locationStatus ?? this.locationStatus,
      locationTier: locationTier ?? this.locationTier,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      address: address ?? this.address,
      captureStatus: captureStatus ?? this.captureStatus,
      lastCapturedPhoto: lastCapturedPhoto ?? this.lastCapturedPhoto,
      errorMessage: errorMessage,
      isGpsOverrideAllowed: isGpsOverrideAllowed ?? this.isGpsOverrideAllowed,
      focusPoint: focusPoint ?? this.focusPoint,
      isFocusIndicatorVisible:
          isFocusIndicatorVisible ?? this.isFocusIndicatorVisible,
      currentTime: currentTime ?? this.currentTime,
      taskPhotos: taskPhotos ?? this.taskPhotos,
      stampConfig: stampConfig ?? this.stampConfig,
      cameraMode: cameraMode ?? this.cameraMode,
      isRecordingVideo: isRecordingVideo ?? this.isRecordingVideo,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      recordedVideoPath: recordedVideoPath ?? this.recordedVideoPath,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      minZoomLevel: minZoomLevel ?? this.minZoomLevel,
      maxZoomLevel: maxZoomLevel ?? this.maxZoomLevel,
      isGridEnabled: isGridEnabled ?? this.isGridEnabled,
      flashMode: flashMode ?? this.flashMode,
      isFlashSupported: isFlashSupported ?? this.isFlashSupported,
      isSwitchingCamera: isSwitchingCamera ?? this.isSwitchingCamera,
      isFlashAnimationActive:
          isFlashAnimationActive ?? this.isFlashAnimationActive,
      cameraPreferences: cameraPreferences ?? this.cameraPreferences,
      isControlPanelOpen: isControlPanelOpen ?? this.isControlPanelOpen,
      remainingTimerSeconds:
          remainingTimerSeconds ?? this.remainingTimerSeconds,
      levelDegrees: levelDegrees ?? this.levelDegrees,
      isLevel: isLevel ?? this.isLevel,
      caption: clearCaption ? null : (caption ?? this.caption),
    );
  }
}

/// GeotagCameraController
/// ----------------------------------------------------------------------
/// Controller sentral yang mengelola:
/// 1. Fast Location Pipeline & validasi integritas GPS live (Phase 2)
/// 2. Mode Foto & Video Recording (Phase 1)
/// 3. Zooming & Flash Mode Management (Phase 1)
/// 4. Tap-to-Focus & Exposure dengan cincin animasi (Phase 1)
/// 5. Template Stamp Management & Live Visual Preview (Phase 3)
/// 6. Advanced Camera Controls: Toolbar, Control Panel, Rasio, Grid, Timer,
///    Focus Guide, Mirror, Sound, Level Sensor, Add Text, Rename, Settings (Phase 4)
/// ----------------------------------------------------------------------
class GeotagCameraController extends ChangeNotifier {
  final ValidateLocationIntegrity validateLocationIntegrity;
  final CaptureGeotaggedPhoto captureGeotaggedPhoto;
  final CreateEvidence? createEvidence;
  final GetTaskPhotoPreviews? getTaskPhotoPreviews;
  final ReverseGeocoder? reverseGeocoder;
  final TemplateRepository? templateRepository;
  final CameraPreferencesRepository? cameraPreferencesRepository;
  final CameraCapabilityService _capabilityService;
  final CameraLevelSensorService _levelSensorService;
  final FileNamingService _fileNamingService;
  final String taskId;

  late GeotagCameraViewState _state;
  GeotagCameraViewState get state => _state;
  CameraCapabilities get capabilities => _capabilityService.capabilities;

  bool _isDisposed = false;
  Timer? _clockTimer;
  Timer? _focusTimer;
  Timer? _recordingTimer;
  Timer? _countdownTimer;
  StreamSubscription<CameraLevelData>? _levelSubscription;

  GeotagCameraController({
    required this.validateLocationIntegrity,
    required this.captureGeotaggedPhoto,
    this.createEvidence,
    this.getTaskPhotoPreviews,
    this.reverseGeocoder,
    this.templateRepository,
    this.cameraPreferencesRepository,
    CameraCapabilityService? capabilityService,
    CameraLevelSensorService? levelSensorService,
    FileNamingService? fileNamingService,
    required this.taskId,
  })  : _capabilityService = capabilityService ?? CameraCapabilityService(),
        _levelSensorService = levelSensorService ?? CameraLevelSensorService(),
        _fileNamingService = fileNamingService ?? FileNamingService() {
    _state = GeotagCameraViewState(currentTime: DateTime.now());
    _startClockTimer();
    _loadTaskPhotos();
    _loadTemplateConfiguration();
    _loadCameraPreferences();
    _startFastLocationPipeline();
  }

  void _updateState(GeotagCameraViewState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  // ====================================================================
  // PREFERENSI & TEMPLATE PERSISTENCE
  // ====================================================================
  Future<void> _loadCameraPreferences() async {
    if (cameraPreferencesRepository == null) return;
    final prefs = await cameraPreferencesRepository!.getPreferences();
    _updateState(
      _state.copyWith(
        cameraPreferences: prefs,
        isGridEnabled: prefs.gridEnabled,
        caption: prefs.customCaption,
      ),
    );

    if (prefs.levelEnabled) {
      _startLevelSensor();
    }
  }

  Future<void> _saveCameraPreferences(CameraPreferencesEntity prefs) async {
    _updateState(_state.copyWith(cameraPreferences: prefs));
    await cameraPreferencesRepository?.savePreferences(prefs);
  }

  Future<void> _loadTemplateConfiguration() async {
    if (templateRepository == null) return;
    final config = await templateRepository!.getSavedConfiguration();
    _updateState(_state.copyWith(stampConfig: config));
  }

  void setTemplate(String templateId) {
    final updated = _state.stampConfig.copyWith(templateId: templateId);
    _updateState(_state.copyWith(stampConfig: updated));
    templateRepository?.saveConfiguration(updated);
  }

  void updateStampConfig(StampConfiguration config) {
    _updateState(_state.copyWith(stampConfig: config));
    templateRepository?.saveConfiguration(config);
  }

  // ====================================================================
  // EXPANDABLE CAMERA CONTROL PANEL (PHASE 4)
  // ====================================================================
  void toggleControlPanel() {
    if (_state.isRecordingVideo) return;
    _updateState(
      _state.copyWith(isControlPanelOpen: !_state.isControlPanelOpen),
    );
  }

  void openControlPanel() {
    if (_state.isRecordingVideo) return;
    _updateState(_state.copyWith(isControlPanelOpen: true));
  }

  void closeControlPanel() {
    if (_state.isControlPanelOpen) {
      _updateState(_state.copyWith(isControlPanelOpen: false));
    }
  }

  // 1. Aspect Ratio Control (4:3 -> 16:9 -> Full -> 4:3)
  void cycleAspectRatio() {
    if (_state.isRecordingVideo) return;
    final current = _state.cameraPreferences.aspectRatio;
    final next = switch (current) {
      CameraAspectRatio.ratio4x3 => CameraAspectRatio.ratio16x9,
      CameraAspectRatio.ratio16x9 => CameraAspectRatio.ratioFull,
      CameraAspectRatio.ratioFull => CameraAspectRatio.ratio4x3,
    };
    setAspectRatio(next);
  }

  void setAspectRatio(CameraAspectRatio ratio) {
    final updated = _state.cameraPreferences.copyWith(aspectRatio: ratio);
    _saveCameraPreferences(updated);
  }

  // 2. Grid Toggle (Off -> 3x3 -> Off)
  void toggleGrid() {
    final newGrid = !_state.isGridEnabled;
    final updated = _state.cameraPreferences.copyWith(gridEnabled: newGrid);
    _updateState(_state.copyWith(isGridEnabled: newGrid));
    _saveCameraPreferences(updated);
  }

  // 3. Timer Control (Off -> 3s -> 5s -> 10s -> Off)
  void cycleTimer() {
    if (_state.isRecordingVideo) return;
    final current = _state.cameraPreferences.timerSeconds;
    final next = switch (current) {
      0 => 3,
      3 => 5,
      5 => 10,
      _ => 0,
    };
    setTimerSeconds(next);
  }

  void setTimerSeconds(int seconds) {
    final updated = _state.cameraPreferences.copyWith(timerSeconds: seconds);
    _saveCameraPreferences(updated);
  }

  // 4. Focus Guide Toggle
  void toggleFocusGuide() {
    final updated = _state.cameraPreferences.copyWith(
      focusGuideEnabled: !_state.cameraPreferences.focusGuideEnabled,
    );
    _saveCameraPreferences(updated);
  }

  // 5. Mirror Front Camera Toggle
  void toggleMirrorFrontCamera() {
    if (_state.isRecordingVideo) return;
    final updated = _state.cameraPreferences.copyWith(
      mirrorFrontCamera: !_state.cameraPreferences.mirrorFrontCamera,
    );
    _saveCameraPreferences(updated);
  }

  // 6. Shutter Sound (System -> Enabled -> Disabled -> System)
  void cycleShutterSound() {
    final current = _state.cameraPreferences.shutterSoundPreference;
    final next = switch (current) {
      ShutterSoundPreference.system => ShutterSoundPreference.enabled,
      ShutterSoundPreference.enabled => ShutterSoundPreference.disabled,
      ShutterSoundPreference.disabled => ShutterSoundPreference.system,
    };
    final updated =
        _state.cameraPreferences.copyWith(shutterSoundPreference: next);
    _saveCameraPreferences(updated);
  }

  // 7. White Balance
  void cycleWhiteBalance() {
    if (!_capabilityService.capabilities.supportsWhiteBalance) return;
    final current = _state.cameraPreferences.whiteBalance;
    final next = switch (current) {
      CameraWhiteBalanceMode.auto => CameraWhiteBalanceMode.daylight,
      CameraWhiteBalanceMode.daylight => CameraWhiteBalanceMode.cloudy,
      CameraWhiteBalanceMode.cloudy => CameraWhiteBalanceMode.fluorescent,
      CameraWhiteBalanceMode.fluorescent => CameraWhiteBalanceMode.incandescent,
      CameraWhiteBalanceMode.incandescent => CameraWhiteBalanceMode.auto,
    };
    setWhiteBalance(next);
  }

  void setWhiteBalance(CameraWhiteBalanceMode mode) {
    final updated = _state.cameraPreferences.copyWith(whiteBalance: mode);
    _saveCameraPreferences(updated);
  }

  // 8. Level Sensor (Waterpass)
  void toggleLevelSensor() {
    final newLevel = !_state.cameraPreferences.levelEnabled;
    final updated = _state.cameraPreferences.copyWith(levelEnabled: newLevel);
    _saveCameraPreferences(updated);

    if (newLevel) {
      _startLevelSensor();
    } else {
      _stopLevelSensor();
    }
  }

  void _startLevelSensor() {
    _stopLevelSensor();
    _levelSensorService.start();
    _levelSubscription = _levelSensorService.levelStream.listen((data) {
      if (_isDisposed) return;
      _updateState(
        _state.copyWith(
          levelDegrees: data.rollDegrees,
          isLevel: data.isLevel,
        ),
      );
    });
  }

  void _stopLevelSensor() {
    _levelSubscription?.cancel();
    _levelSubscription = null;
    _levelSensorService.stop();
  }

  // 9. Video Audio Toggle
  void toggleVideoAudio() {
    if (_state.isRecordingVideo) return;
    final updated = _state.cameraPreferences.copyWith(
      videoAudioEnabled: !_state.cameraPreferences.videoAudioEnabled,
    );
    _saveCameraPreferences(updated);
  }

  // 10. Kualitas Foto & Video
  void setPhotoQuality(PhotoQualityPreference quality) {
    final updated = _state.cameraPreferences.copyWith(photoQuality: quality);
    _saveCameraPreferences(updated);
  }

  void setVideoQuality(VideoQualityPreference quality) {
    final updated = _state.cameraPreferences.copyWith(videoQuality: quality);
    _saveCameraPreferences(updated);
  }

  // 11. Add Text (Caption)
  void setCustomCaption(String? caption) {
    final updated = _state.cameraPreferences.copyWith(customCaption: caption);
    _updateState(_state.copyWith(caption: caption));
    _saveCameraPreferences(updated);
  }

  // 12. Pola Penamaan Berkas
  void setFileNaming(FileNamingMode mode, String? customPrefix) {
    final updated = _state.cameraPreferences.copyWith(
      fileNamingMode: mode,
      customFilePrefix: customPrefix,
    );
    _saveCameraPreferences(updated);
  }

  // 13. Tombol Volume Shutter
  void setVolumeButtonShutter(bool enabled) {
    final updated =
        _state.cameraPreferences.copyWith(volumeButtonShutter: enabled);
    _saveCameraPreferences(updated);
  }

  // 14. Reset Pengaturan Kamera
  Future<void> resetCameraPreferences() async {
    const defaultPrefs = CameraPreferencesEntity();
    await cameraPreferencesRepository?.resetToDefaults();
    _updateState(
      _state.copyWith(
        cameraPreferences: defaultPrefs,
        isGridEnabled: false,
        clearCaption: true,
      ),
    );
    _stopLevelSensor();
  }

  // ====================================================================
  // TIMER COUNTDOWN EXECUTION
  // ====================================================================
  void cancelTimerCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _updateState(_state.copyWith(remainingTimerSeconds: 0));
  }

  Future<void> _executeWithTimer({
    required Future<void> Function() onComplete,
  }) async {
    final timerSec = _state.cameraPreferences.timerSeconds;
    if (timerSec <= 0) {
      await onComplete();
      return;
    }

    closeControlPanel();
    _updateState(_state.copyWith(remainingTimerSeconds: timerSec));

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      final remaining = _state.remainingTimerSeconds - 1;
      if (remaining > 0) {
        HapticFeedback.selectionClick();
        _updateState(_state.copyWith(remainingTimerSeconds: remaining));
      } else {
        timer.cancel();
        _countdownTimer = null;
        _updateState(_state.copyWith(remainingTimerSeconds: 0));
        // Reset timer session ke 0 setelah dieksekusi (session-reset)
        setTimerSeconds(0);
        await onComplete();
      }
    });
  }

  void updateZoomBounds({
    required double minZoom,
    required double maxZoom,
  }) {
    _updateState(
      _state.copyWith(
        minZoomLevel: minZoom,
        maxZoomLevel: maxZoom,
      ),
    );
  }

  void updateFlashSupport({required bool isSupported}) {
    _updateState(
      _state.copyWith(
        isFlashSupported: isSupported,
        flashMode: isSupported ? _state.flashMode : FlashMode.off,
      ),
    );
  }

  void setSwitchingCamera(bool isSwitching) {
    _updateState(
      _state.copyWith(isSwitchingCamera: isSwitching),
    );
  }

  // ====================================================================
  // CAMERA HARDWARE EVALUATION
  // ====================================================================
  Future<void> evaluateHardwareCapabilities({
    required List<CameraDescription> availableCameras,
    CameraController? activeController,
  }) async {
    await _capabilityService.evaluate(
      availableCameras: availableCameras,
      activeController: activeController,
    );
    notifyListeners();
  }

  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;
      _updateState(_state.copyWith(currentTime: DateTime.now()));
    });
  }

  Future<void> refreshTaskPhotos() => _loadTaskPhotos();

  Future<void> _loadTaskPhotos() async {
    if (getTaskPhotoPreviews == null) return;
    final result = await getTaskPhotoPreviews!(taskId);
    result.fold(
      (_) => null,
      (photos) => _updateState(_state.copyWith(taskPhotos: photos)),
    );
  }

  // ====================================================================
  // FAST LOCATION PIPELINE INTEGRATION
  // ====================================================================
  void _startFastLocationPipeline({Position? initialCandidate}) {
    if (reverseGeocoder != null) {
      FastLocationService.instance.setReverseGeocoder(reverseGeocoder!);
    }

    final warmCandidate =
        initialCandidate ??
        FastLocationService.instance.latestCandidatePosition;
    if (warmCandidate != null) {
      _applyLocationData(
        FastLocationData(
          tier: warmCandidate.accuracy <= 15.0 && !warmCandidate.isMocked
              ? LocationTier.verified
              : LocationTier.fastInitial,
          position: warmCandidate,
          latitude: warmCandidate.latitude,
          longitude: warmCandidate.longitude,
          accuracy: warmCandidate.accuracy,
          timestamp: warmCandidate.timestamp,
          isMocked: warmCandidate.isMocked,
        ),
      );
    } else {
      _checkLocationOnce();
    }

    FastLocationService.instance.startActiveCameraStream(
      onLocationUpdate: (data) {
        if (_isDisposed) return;
        _applyLocationData(data);
      },
      initialCandidate: warmCandidate,
    );
  }

  Future<void> _checkLocationOnce() async {
    final result = await validateLocationIntegrity();
    if (_isDisposed) return;
    result.fold(
      (failure) => _updateState(
        _state.copyWith(
          locationStatus: LocationIntegrityStatus.invalid,
          errorMessage: failure.message,
        ),
      ),
      (checkResult) {
        final tier = checkResult.accuracyMeters <= 15.0
            ? LocationTier.verified
            : (checkResult.accuracyMeters <= 30.0
                ? LocationTier.freshRefining
                : LocationTier.fastInitial);
        _updateState(
          _state.copyWith(
            locationStatus: checkResult.status,
            latitude: checkResult.latitude,
            longitude: checkResult.longitude,
            accuracyMeters: checkResult.accuracyMeters,
            locationTier: tier,
            errorMessage: checkResult.status == LocationIntegrityStatus.invalid
                ? 'Lokasi tidak valid atau terdeteksi manipulasi.'
                : null,
          ),
        );
      },
    );
  }

  void _applyLocationData(FastLocationData data) {
    if (_isDisposed) return;

    if (data.isMocked) {
      _updateState(
        _state.copyWith(
          locationStatus: LocationIntegrityStatus.invalid,
          errorMessage: 'Mock Location / Fake GPS terdeteksi.',
          latitude: data.latitude,
          longitude: data.longitude,
          accuracyMeters: data.accuracy,
          locationTier: LocationTier.none,
          address: data.address,
        ),
      );
      return;
    }

    final isValid = data.latitude != null && data.longitude != null;
    _updateState(
      _state.copyWith(
        locationStatus: isValid
            ? LocationIntegrityStatus.valid
            : LocationIntegrityStatus.checking,
        latitude: data.latitude,
        longitude: data.longitude,
        accuracyMeters: data.accuracy,
        locationTier: data.tier,
        address: data.address ?? _state.address,
        errorMessage: null,
      ),
    );
  }

  // ====================================================================
  // FLASH & ZOOM & FOCUS CONTROLS
  // ====================================================================
  Future<void> cycleFlashMode(
    CameraController? cameraController,
    CameraLensDirection lensDirection,
  ) async {
    if (lensDirection == CameraLensDirection.front) {
      _updateState(_state.copyWith(isFlashSupported: false));
      return;
    }

    FlashMode nextMode;
    switch (_state.flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.off;
        break;
    }

    if (cameraController != null && cameraController.value.isInitialized) {
      try {
        await cameraController.setFlashMode(nextMode);
      } catch (_) {
        try {
          await cameraController.setFlashMode(FlashMode.off);
          nextMode = FlashMode.off;
        } catch (_) {}
      }
    }

    _updateState(
      _state.copyWith(
        flashMode: nextMode,
        isFlashSupported: true,
      ),
    );
  }

  Future<void> setZoomLevel(
    double zoom,
    CameraController? cameraController,
  ) async {
    final targetZoom = zoom.clamp(_state.minZoomLevel, _state.maxZoomLevel);
    if (cameraController != null && cameraController.value.isInitialized) {
      try {
        await cameraController.setZoomLevel(targetZoom);
      } catch (_) {}
    }
    _updateState(_state.copyWith(zoomLevel: targetZoom));
  }

  Future<void> handleTapToFocus({
    required Offset localOffset,
    required Size previewSize,
    required CameraController? cameraController,
  }) async {
    final dx = (localOffset.dx / previewSize.width).clamp(0.0, 1.0);
    final dy = (localOffset.dy / previewSize.height).clamp(0.0, 1.0);
    final point = Offset(dx, dy);

    if (cameraController != null && cameraController.value.isInitialized) {
      try {
        if (_state.cameraPreferences.focusGuideEnabled) {
          await cameraController.setFocusPoint(point);
          await cameraController.setExposurePoint(point);
        }
      } catch (_) {}
    }
    showFocusIndicator(localOffset);
  }

  void showFocusIndicator(Offset position) {
    if (!_state.cameraPreferences.focusGuideEnabled) return;
    _focusTimer?.cancel();
    _updateState(
      _state.copyWith(
        focusPoint: position,
        isFocusIndicatorVisible: true,
      ),
    );

    _focusTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_isDisposed) return;
      _updateState(_state.copyWith(isFocusIndicatorVisible: false));
    });
  }

  void triggerCaptureFlash() {
    _updateState(_state.copyWith(isFlashAnimationActive: true));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isDisposed) return;
      _updateState(_state.copyWith(isFlashAnimationActive: false));
    });
  }

  void setCameraMode(CameraCaptureMode mode) {
    if (_state.isRecordingVideo) return;
    _updateState(
      _state.copyWith(
        cameraMode: mode,
        errorMessage: null,
      ),
    );
  }

  void allowGpsOverride() {
    _updateState(_state.copyWith(isGpsOverrideAllowed: true));
    onCaptureButtonPressed();
  }

  // ====================================================================
  // ATOMIC CAPTURE & VIDEO RECORDING WITH TIMER
  // ====================================================================
  Future<void> onCaptureButtonPressed() async {
    if (!_state.isCaptureEnabled) return;

    if (_state.cameraPreferences.timerSeconds > 0) {
      await _executeWithTimer(onComplete: () => _performCapturePhoto());
    } else {
      await _performCapturePhoto();
    }
  }

  Future<void> _performCapturePhoto() async {
    triggerCaptureFlash();
    _updateState(_state.copyWith(captureStatus: CaptureViewStatus.capturing));

    final result = await captureGeotaggedPhoto(
      taskId: taskId,
      caption: _state.caption,
    );

    if (_isDisposed) return;

    result.fold(
      (failure) => _updateState(
        _state.copyWith(
          captureStatus: CaptureViewStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (photo) {
        _updateState(
          _state.copyWith(
            captureStatus: CaptureViewStatus.previewing,
            lastCapturedPhoto: photo,
          ),
        );
        _loadTaskPhotos();
      },
    );
  }

  Future<void> startVideoRecording(CameraController? cameraController) async {
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (_state.isRecordingVideo) return;

    closeControlPanel();

    if (_state.cameraPreferences.timerSeconds > 0) {
      await _executeWithTimer(
        onComplete: () => _performStartVideoRecording(cameraController),
      );
    } else {
      await _performStartVideoRecording(cameraController);
    }
  }

  Future<void> _performStartVideoRecording(
    CameraController? cameraController,
  ) async {
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    try {
      await cameraController.startVideoRecording();
      _updateState(
        _state.copyWith(
          isRecordingVideo: true,
          recordingDuration: Duration.zero,
          errorMessage: null,
        ),
      );

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_isDisposed || !_state.isRecordingVideo) return;
        _updateState(
          _state.copyWith(
            recordingDuration:
                _state.recordingDuration + const Duration(seconds: 1),
          ),
        );
      });
    } catch (e) {
      _updateState(
        _state.copyWith(
          isRecordingVideo: false,
          errorMessage: 'Gagal memulai perekaman video: $e',
        ),
      );
    }
  }

  Future<String?> stopVideoRecording(CameraController? cameraController) async {
    if (cameraController == null || !cameraController.value.isInitialized) {
      return null;
    }
    if (!_state.isRecordingVideo) return null;

    _recordingTimer?.cancel();

    try {
      final XFile file = await cameraController.stopVideoRecording();
      final videoPath = file.path;

      final videoFile = File(videoPath);
      if (await videoFile.exists() && await videoFile.length() > 0) {
        _updateState(
          _state.copyWith(
            isRecordingVideo: false,
            recordedVideoPath: videoPath,
            errorMessage: null,
          ),
        );
        return videoPath;
      } else {
        _updateState(
          _state.copyWith(
            isRecordingVideo: false,
            errorMessage: 'File video tidak tersimpan atau berukuran 0 byte.',
          ),
        );
        return null;
      }
    } catch (e) {
      _updateState(
        _state.copyWith(
          isRecordingVideo: false,
          errorMessage: 'Gagal menghentikan perekaman video: $e',
        ),
      );
      return null;
    }
  }

  Future<bool> saveRecordedVideoEvidence({String? caption}) async {
    final videoPath = _state.recordedVideoPath;
    if (videoPath == null) return false;

    _updateState(_state.copyWith(captureStatus: CaptureViewStatus.capturing));

    if (createEvidence != null) {
      final result = await createEvidence!.saveVideo(
        taskId: taskId,
        videoPath: videoPath,
        duration: _state.recordingDuration,
        caption: caption ?? _state.caption,
      );

      if (_isDisposed) return false;

      return result.fold(
        (failure) {
          _updateState(
            _state.copyWith(
              captureStatus: CaptureViewStatus.error,
              errorMessage: failure.message,
            ),
          );
          return false;
        },
        (evidence) {
          _updateState(
            _state.copyWith(
              captureStatus: CaptureViewStatus.previewing,
              lastCapturedPhoto: evidence,
              recordedVideoPath: null,
            ),
          );
          _loadTaskPhotos();
          return true;
        },
      );
    }
    return false;
  }

  void retakeVideo() {
    _updateState(
      _state.copyWith(
        recordedVideoPath: null,
        recordingDuration: Duration.zero,
      ),
    );
  }

  void retakePhoto() {
    _updateState(
      _state.copyWith(
        captureStatus: CaptureViewStatus.idle,
        lastCapturedPhoto: null,
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _clockTimer?.cancel();
    _focusTimer?.cancel();
    _recordingTimer?.cancel();
    _countdownTimer?.cancel();
    _stopLevelSensor();
    _levelSensorService.dispose();
    FastLocationService.instance.stopActiveCameraStream();
    super.dispose();
  }
}
