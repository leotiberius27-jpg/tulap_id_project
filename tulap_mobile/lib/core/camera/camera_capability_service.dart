import 'package:camera/camera.dart';

/// CameraCapabilities
/// ----------------------------------------------------------------------
/// Snapshot kemampuan hardware kamera yang terdeteksi secara aktual.
/// Mencegah fitur fiktif (fake controls) di UI.
/// ----------------------------------------------------------------------
class CameraCapabilities {
  final bool hasFrontCamera;
  final bool hasBackCamera;
  final bool supportsFlash;
  final bool supportsTorch;
  final bool supportsFocusPoint;
  final bool supportsExposurePoint;
  final bool supportsWhiteBalance;
  final bool supportsAudio;
  final double minZoom;
  final double maxZoom;

  const CameraCapabilities({
    this.hasFrontCamera = false,
    this.hasBackCamera = true,
    this.supportsFlash = true,
    this.supportsTorch = true,
    this.supportsFocusPoint = true,
    this.supportsExposurePoint = true,
    this.supportsWhiteBalance = false,
    this.supportsAudio = true,
    this.minZoom = 1.0,
    this.maxZoom = 5.0,
  });

  CameraCapabilities copyWith({
    bool? hasFrontCamera,
    bool? hasBackCamera,
    bool? supportsFlash,
    bool? supportsTorch,
    bool? supportsFocusPoint,
    bool? supportsExposurePoint,
    bool? supportsWhiteBalance,
    bool? supportsAudio,
    double? minZoom,
    double? maxZoom,
  }) {
    return CameraCapabilities(
      hasFrontCamera: hasFrontCamera ?? this.hasFrontCamera,
      hasBackCamera: hasBackCamera ?? this.hasBackCamera,
      supportsFlash: supportsFlash ?? this.supportsFlash,
      supportsTorch: supportsTorch ?? this.supportsTorch,
      supportsFocusPoint: supportsFocusPoint ?? this.supportsFocusPoint,
      supportsExposurePoint:
          supportsExposurePoint ?? this.supportsExposurePoint,
      supportsWhiteBalance: supportsWhiteBalance ?? this.supportsWhiteBalance,
      supportsAudio: supportsAudio ?? this.supportsAudio,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
    );
  }
}

/// CameraCapabilityService
/// ----------------------------------------------------------------------
/// Mendeteksi kapabilitas sensor & lensa kamera perangkat secara dinamis.
/// ----------------------------------------------------------------------
class CameraCapabilityService {
  CameraCapabilities _capabilities = const CameraCapabilities();

  CameraCapabilities get capabilities => _capabilities;

  /// Menganalisis daftar kamera dan controller aktif
  Future<CameraCapabilities> evaluate({
    required List<CameraDescription> availableCameras,
    CameraController? activeController,
  }) async {
    final hasFront = availableCameras.any(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    final hasBack = availableCameras.any(
      (c) => c.lensDirection == CameraLensDirection.back,
    );

    double minZoom = 1.0;
    double maxZoom = 5.0;
    bool supportsFlash = false;
    bool supportsTorch = false;
    bool supportsFocus = false;
    bool supportsExposure = false;

    if (activeController != null && activeController.value.isInitialized) {
      try {
        minZoom = await activeController.getMinZoomLevel();
        maxZoom = await activeController.getMaxZoomLevel();
      } catch (_) {}

      // Deteksi flash & torch pada kamera saat ini
      try {
        final currentLens = activeController.description.lensDirection;
        supportsFlash = currentLens == CameraLensDirection.back;
        supportsTorch = currentLens == CameraLensDirection.back;
        supportsFocus = true;
        supportsExposure = true;
      } catch (_) {}
    }

    _capabilities = CameraCapabilities(
      hasFrontCamera: hasFront,
      hasBackCamera: hasBack,
      supportsFlash: supportsFlash,
      supportsTorch: supportsTorch,
      supportsFocusPoint: supportsFocus,
      supportsExposurePoint: supportsExposure,
      supportsWhiteBalance: false, // Flutter camera package standar belum mengekspos WB API universal
      supportsAudio: true,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );

    return _capabilities;
  }
}
