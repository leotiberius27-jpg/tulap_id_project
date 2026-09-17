import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/camera/camera_capability_service.dart';
import '../../../../core/camera/camera_level_sensor_service.dart';
import '../../../../core/geo/reverse_geocoder.dart';
import '../../../assistant/presentation/controllers/tula_visibility_controller.dart';
import '../../domain/repositories/camera_preferences_repository.dart';
import '../../domain/repositories/template_repository.dart';
import '../../domain/usecases/capture_geotagged_photo.dart';
import '../../domain/usecases/create_evidence.dart';
import '../../domain/usecases/get_task_photo_previews.dart';
import '../../domain/usecases/validate_location_integrity.dart';
import '../controllers/geotag_camera_controller.dart';
import 'geotag_camera_page.dart';

/// GeotagCameraEntryPage
/// ----------------------------------------------------------------------
/// Entrypoint layar kamera Geotagged Camera:
/// - Menginisialisasi CameraController secara asinkron dengan audio untuk video
/// - Mendukung switch/flip antara kamera belakang dan kamera depan
/// - Mengelola lifecycle aplikasi (pause saat latar belakang, resume otomatis)
/// - Menghitung batasan zoom hardware & kapabilitas lampu kilat
/// - Mendaftarkan sesi kamera ke dependency injection (DI)
/// - Membersihkan resource saat ditutup
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

class _GeotagCameraEntryPageState extends State<GeotagCameraEntryPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  GeotagCameraController? _geotagController;
  CameraLensDirection _currentLensDirection = CameraLensDirection.back;
  String? _initError;
  bool _isSwitchingCamera = false;
  bool _isInitializing = false;
  late final TulaVisibilityController _tula;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Camera fullscreen = Tula tersembunyi total selama sesi kamera aktif
    // (Bagian 6 spesifikasi redesign Tula - mencegah salah tap).
    _tula = sl<TulaVisibilityController>();
    _tula.suppress();

    _geotagController = GeotagCameraController(
      validateLocationIntegrity: sl<ValidateLocationIntegrity>(),
      captureGeotaggedPhoto: sl<CaptureGeotaggedPhoto>(),
      createEvidence:
          sl.isRegistered<CreateEvidence>() ? sl<CreateEvidence>() : null,
      getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
      reverseGeocoder: sl<ReverseGeocoder>(),
      templateRepository: sl.isRegistered<TemplateRepository>()
          ? sl<TemplateRepository>()
          : null,
      cameraPreferencesRepository:
          sl.isRegistered<CameraPreferencesRepository>()
              ? sl<CameraPreferencesRepository>()
              : null,
      capabilityService: sl.isRegistered<CameraCapabilityService>()
          ? sl<CameraCapabilityService>()
          : null,
      levelSensorService: sl.isRegistered<CameraLevelSensorService>()
          ? sl<CameraLevelSensorService>()
          : null,
      taskId: widget.taskId,
    );

    _initializeCamera(_currentLensDirection);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? camera = _cameraController;

    // Aplikasi berpindah ke background atau non-aktif
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_geotagController?.state.isRecordingVideo == true) {
        _geotagController?.stopVideoRecording(camera);
      }
      _cameraController?.dispose();
      unregisterCameraSession();

      // PENTING: setState WAJIB dipanggil di sini, bukan hanya
      // menugaskan _cameraController = null secara diam-diam. Tanpa ini,
      // widget tree yang sudah ter-mount (GeotagCameraPage) tetap
      // memegang referensi controller yang baru saja di-dispose - lalu
      // rebuild APAPUN yang terjadi sebelum _initializeCamera() selesai
      // (mis. tick FastLocationService yang memanggil notifyListeners()
      // sangat sering saat GPS warm-up) memicu CameraPreview memanggil
      // buildPreview() pada controller yang sudah disposed, melempar
      // "CameraException(Disposed CameraController, ...)" berulang kali.
      // Dikonfirmasi nyata lewat live-test di perangkat fisik: Android
      // sering mengirim satu blip inactive->resumed persis sesaat
      // setelah cold-launch, memicu race ini walau user tidak pernah
      // benar-benar membuka aplikasi lain.
      if (mounted) {
        setState(() => _cameraController = null);
      } else {
        _cameraController = null;
      }
    }
    // Aplikasi kembali ke foreground (resumed)
    else if (state == AppLifecycleState.resumed) {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        _initializeCamera(_currentLensDirection);
      }
    }
  }

  Future<void> _initializeCamera(CameraLensDirection direction) async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _initError =
                'Perangkat tidak memiliki sensor kamera yang tersedia.';
            _isInitializing = false;
            _isSwitchingCamera = false;
          });
        }
        return;
      }

      final selectedCamera = cameras.firstWhere(
        (c) => c.lensDirection == direction,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: true, // Audio aktif untuk video dokumentasi
      );

      await controller.initialize();

      // Hitung batas zoom level hardware
      double minZoom = 1.0;
      double maxZoom = 8.0;
      try {
        minZoom = await controller.getMinZoomLevel();
        maxZoom = await controller.getMaxZoomLevel();
      } catch (_) {}

      _geotagController?.updateZoomBounds(
        minZoom: minZoom,
        maxZoom: maxZoom,
      );

      // Periksa kapabilitas flash (kamera depan biasanya tidak memiliki hardware flash)
      final isFlashSupported = selectedCamera.lensDirection == CameraLensDirection.back;
      _geotagController?.updateFlashSupport(isSupported: isFlashSupported);

      // Evaluasi kapabilitas hardware komprehensif (Phase 4)
      await _geotagController?.evaluateHardwareCapabilities(
        availableCameras: cameras,
        activeController: controller,
      );

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
        _isInitializing = false;
        _initError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError =
              'Izin kamera diperlukan untuk membuat dokumentasi kegiatan. Periksa izin pada pengaturan perangkat Anda.';
          _isSwitchingCamera = false;
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_isSwitchingCamera || _cameraController == null || _isInitializing) return;

    setState(() => _isSwitchingCamera = true);
    _geotagController?.setSwitchingCamera(true);

    final targetDirection = _currentLensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    // Bersihkan controller kamera sebelumnya secara aman
    await _cameraController?.dispose();
    _cameraController = null;
    unregisterCameraSession();

    await _initializeCamera(targetDirection);
    _geotagController?.setSwitchingCamera(false);
  }

  @override
  void dispose() {
    _tula.unsuppress();
    WidgetsBinding.instance.removeObserver(this);
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
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0x33EF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.no_photography_rounded,
                    color: Colors.white,
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _initializeCamera(_currentLensDirection),
                        child: const Text('Coba Lagi'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006EE6),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Kembali'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_cameraController == null ||
        _geotagController == null ||
        _isSwitchingCamera ||
        !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1220),
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
                'Menyiapkan kamera...',
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
      currentLensDirection: _currentLensDirection,
      officerName: widget.officerName,
      agencyName: widget.agencyName,
      taskId: widget.taskId,
      taskName: widget.taskName,
      onFlipCamera: _flipCamera,
    );
  }
}
