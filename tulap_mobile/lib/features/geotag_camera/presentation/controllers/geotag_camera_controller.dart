import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/geo/fast_location_service.dart';
import '../../../../core/geo/reverse_geocoder.dart';
import '../../domain/entities/geotag_photo_entity.dart';
import '../../domain/usecases/capture_geotagged_photo.dart';
import '../../domain/usecases/get_task_photo_previews.dart';
import '../../domain/usecases/validate_location_integrity.dart';

/// GeotagCameraViewState
/// ----------------------------------------------------------------------
/// State UI layar kamera Geotagged Camera:
/// - Status tier lokasi 3-level (fastInitial, freshRefining, verified, dll)
/// - Koordinat latitude, longitude, akurasi live, & alamat
/// - State foto capture, galeri task photos, & indikator fokus
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
  });

  /// Ambang batas akurasi "GPS Akurat" untuk capture resmi (<= 15m).
  static const double gpsLockAccuracyMeters = 15.0;

  bool get isGpsLocked =>
      accuracyMeters != null && accuracyMeters! <= gpsLockAccuracyMeters;

  bool get isAcceptable => accuracyMeters != null && accuracyMeters! <= 30.0;

  /// Tombol capture aktif jika lokasi valid (lolos anti-mock & root),
  /// akurasi mencukupi (<= 15m) ATAU user memilih "Ambil dengan Catatan" (override),
  /// dan tidak sedang memproses capture.
  bool get isCaptureEnabled =>
      locationStatus == LocationIntegrityStatus.valid &&
      (isGpsLocked || isGpsOverrideAllowed) &&
      captureStatus != CaptureViewStatus.capturing;

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
    );
  }
}

/// GeotagCameraController
/// ----------------------------------------------------------------------
/// Mengelola Fast Location Pipeline, live GPS stream refinement,
/// reverse geocoding paralel, timer jam live, dan proses capture instan.
/// ----------------------------------------------------------------------
class GeotagCameraController extends ChangeNotifier {
  final ValidateLocationIntegrity _validateLocationIntegrity;
  final CaptureGeotaggedPhoto _captureGeotaggedPhoto;
  final GetTaskPhotoPreviews? _getTaskPhotoPreviews;
  final ReverseGeocoder? _reverseGeocoder;
  final String taskId;

  late GeotagCameraViewState _state;
  GeotagCameraViewState get state => _state;

  bool _isDisposed = false;
  Timer? _clockTimer;
  Timer? _focusTimer;

  GeotagCameraController({
    required ValidateLocationIntegrity validateLocationIntegrity,
    required CaptureGeotaggedPhoto captureGeotaggedPhoto,
    GetTaskPhotoPreviews? getTaskPhotoPreviews,
    ReverseGeocoder? reverseGeocoder,
    required this.taskId,
  }) : _validateLocationIntegrity = validateLocationIntegrity,
       _captureGeotaggedPhoto = captureGeotaggedPhoto,
       _getTaskPhotoPreviews = getTaskPhotoPreviews,
       _reverseGeocoder = reverseGeocoder {
    _state = GeotagCameraViewState(currentTime: DateTime.now());
    _startClockTimer();
    _loadTaskPhotos();
    _startFastLocationPipeline();
  }

  void _updateState(GeotagCameraViewState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;
      _updateState(_state.copyWith(currentTime: DateTime.now()));
    });
  }

  Future<void> _loadTaskPhotos() async {
    if (_getTaskPhotoPreviews == null) return;
    final result = await _getTaskPhotoPreviews(taskId);
    result.fold(
      (_) => null,
      (photos) => _updateState(_state.copyWith(taskPhotos: photos)),
    );
  }

  // ====================================================================
  // FAST LOCATION PIPELINE INTEGRATION
  // ====================================================================
  void _startFastLocationPipeline({Position? initialCandidate}) {
    if (_reverseGeocoder != null) {
      FastLocationService.instance.setReverseGeocoder(_reverseGeocoder);
    }

    // 1. Ambil kandidat warm location atau last-known secara instan
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

    // 2. Mulai fresh high-accuracy position stream
    FastLocationService.instance.startActiveCameraStream(
      onLocationUpdate: (data) {
        if (_isDisposed) return;
        _applyLocationData(data);
      },
      initialCandidate: warmCandidate,
    );
  }

  Future<void> _checkLocationOnce() async {
    final result = await _validateLocationIntegrity();
    if (_isDisposed) return;
    result.fold(
      (failure) => _updateState(
        _state.copyWith(
          locationStatus: LocationIntegrityStatus.invalid,
          errorMessage: failure.message,
        ),
      ),
      (checkResult) {
        _updateState(
          _state.copyWith(
            locationStatus: checkResult.status,
            latitude: checkResult.latitude,
            longitude: checkResult.longitude,
            accuracyMeters: checkResult.accuracyMeters,
            errorMessage: null,
          ),
        );
      },
    );
  }

  void _applyLocationData(FastLocationData data) {
    final LocationIntegrityStatus mappedStatus;
    if (data.isMocked || data.tier == LocationTier.mocked) {
      mappedStatus = LocationIntegrityStatus.invalid;
    } else if (data.tier == LocationTier.disabled ||
        data.tier == LocationTier.denied) {
      mappedStatus = LocationIntegrityStatus.invalid;
    } else if (data.latitude != null && data.longitude != null) {
      mappedStatus = LocationIntegrityStatus.valid;
    } else {
      mappedStatus = LocationIntegrityStatus.checking;
    }

    _updateState(
      _state.copyWith(
        locationStatus: mappedStatus,
        locationTier: data.tier,
        latitude: data.latitude ?? _state.latitude,
        longitude: data.longitude ?? _state.longitude,
        accuracyMeters: data.accuracy ?? _state.accuracyMeters,
        address: data.address ?? _state.address,
        errorMessage: data.errorMessage,
      ),
    );
  }

  /// Menampilkan animasi cincin fokus kamera di posisi tap
  void showFocusIndicator(Offset point) {
    _focusTimer?.cancel();
    _updateState(
      _state.copyWith(focusPoint: point, isFocusIndicatorVisible: true),
    );

    _focusTimer = Timer(const Duration(milliseconds: 700), () {
      if (_isDisposed) return;
      _updateState(_state.copyWith(isFocusIndicatorVisible: false));
    });
  }

  /// Mengizinkan capture override ("Ambil dengan Catatan") saat akurasi GPS belum optimal
  void allowGpsOverride() {
    _updateState(_state.copyWith(isGpsOverrideAllowed: true));
    onCaptureButtonPressed();
  }

  /// Dipanggil saat user menekan tombol capture besar (Atomic Shutter)
  Future<void> onCaptureButtonPressed() async {
    if (!_state.isCaptureEnabled) return;

    _updateState(_state.copyWith(captureStatus: CaptureViewStatus.capturing));

    final result = await _captureGeotaggedPhoto(taskId: taskId);

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
        _loadTaskPhotos(); // Refresh galeri
      },
    );
  }

  /// Dipanggil saat user menekan "Ambil Ulang" di layar preview
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
    FastLocationService.instance.stopActiveCameraStream();
    super.dispose();
  }
}
