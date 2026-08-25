import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/geo/reverse_geocoder.dart';
import '../../domain/usecases/capture_geotagged_photo.dart';
import '../../domain/usecases/get_task_photo_previews.dart';
import '../../domain/usecases/validate_location_integrity.dart';
import '../controllers/geotag_camera_controller.dart';
import 'geotag_camera_page.dart';

/// GeotagCameraEntryPage
/// ----------------------------------------------------------------------
/// Entrypoint layar kamera Geotagged Camera:
/// - Menginisialisasi CameraController secara asinkron
/// - Mendukung switch/flip antara kamera belakang dan kamera depan
/// - Mendaftarkan sesi kamera ke dependency injection (DI)
/// - Menghubungkan usecase validasi integritas lokasi & reverse geocoding
/// - Membersihkan resource (dispose controller & unregister DI) saat ditutup
/// ----------------------------------------------------------------------
class GeotagCameraEntryPage extends StatefulWidget {
  final String officerName;
  final String agencyName;
  final String taskId;
  final String? taskName;

  const GeotagCameraEntryPage({
    super.key,
    required this.officerName,
    required this.agencyName,
    required this.taskId,
    this.taskName,
  });

  @override
  State<GeotagCameraEntryPage> createState() => _GeotagCameraEntryPageState();
}

class _GeotagCameraEntryPageState extends State<GeotagCameraEntryPage> {
  CameraController? _cameraController;
  GeotagCameraController? _geotagController;
  CameraLensDirection _currentLensDirection = CameraLensDirection.back;
  String? _initError;
  bool _isSwitchingCamera = false;

  @override
  void initState() {
    super.initState();
    _geotagController = GeotagCameraController(
      validateLocationIntegrity: sl<ValidateLocationIntegrity>(),
      captureGeotaggedPhoto: sl<CaptureGeotaggedPhoto>(),
      getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
      reverseGeocoder: sl<ReverseGeocoder>(),
      taskId: widget.taskId,
    );
    _initializeCamera(_currentLensDirection);
  }

  Future<void> _initializeCamera(CameraLensDirection direction) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(
            () => _initError =
                'Perangkat tidak memiliki sensor kamera yang tersedia.',
          );
        }
        return;
      }

      final selectedCamera = cameras.firstWhere(
        (c) => c.lensDirection == direction,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      // Daftarkan session kamera ke GetIt service locator
      registerCameraSession(controller);

      if (!mounted) {
        _geotagController?.dispose();
        await controller.dispose();
        unregisterCameraSession();
        return;
      }

      setState(() {
        _cameraController = controller;
        _currentLensDirection = selectedCamera.lensDirection;
        _isSwitchingCamera = false;
        _initError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError =
              'Kamera tidak dapat diakses. Periksa izin kamera pada pengaturan perangkat.';
          _isSwitchingCamera = false;
        });
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_isSwitchingCamera || _cameraController == null) return;

    setState(() => _isSwitchingCamera = true);

    final targetDirection = _currentLensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    // Bersihkan controller kamera sebelumnya
    await _cameraController?.dispose();
    unregisterCameraSession();

    await _initializeCamera(targetDirection);
  }

  @override
  void dispose() {
    _geotagController?.dispose();
    _cameraController?.dispose();
    unregisterCameraSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.no_photography_rounded,
                    color: Colors.white70,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Kamera Tidak Dapat Diakses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_cameraController == null ||
        _geotagController == null ||
        _isSwitchingCamera) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF006EE6),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Menyiapkan Kamera & Sinyal GPS...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return GeotagCameraPage(
      cameraController: _cameraController!,
      geotagController: _geotagController!,
      officerName: widget.officerName,
      agencyName: widget.agencyName,
      taskId: widget.taskId,
      taskName: widget.taskName,
      onFlipCamera: _flipCamera,
    );
  }
}
