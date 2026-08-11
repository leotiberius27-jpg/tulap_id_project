import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../domain/entities/geotag_photo_entity.dart';
import '../../domain/usecases/capture_geotagged_photo.dart';
import '../../domain/usecases/validate_location_integrity.dart';
import '../controllers/geotag_camera_controller.dart';
import 'geotag_camera_page.dart';

/// GeotagCameraEntryPage
/// ----------------------------------------------------------------------
/// INI yang sebenarnya dipanggil lewat `Navigator.push` dari Detail
/// Tugas ("Foto Kegiatan" quick action) - BUKAN GeotagCameraPage
/// langsung. Halaman ini menangani seluruh siklus hidup yang butuh
/// async & harus dibersihkan dengan benar:
///
///   1. `availableCameras()` -> pilih kamera belakang -> inisialisasi
///      CameraController (async, perlu loading state).
///   2. `registerCameraSession(controller)` -> mendaftarkan
///      GeotagCameraRepository & usecase terkait ke service locator
///      untuk sesi kamera kali ini.
///   3. Membuat GeotagCameraController dari usecase yang baru
///      terdaftar, lalu merender GeotagCameraPage yang sesungguhnya.
///   4. Saat halaman ditutup (dispose): controller di-dispose, kamera
///      dilepas, DAN `unregisterCameraSession()` dipanggil - mencegah
///      memory leak dan referensi ke CameraController yang sudah mati.
/// ----------------------------------------------------------------------
class GeotagCameraEntryPage extends StatefulWidget {
  final String officerName;
  final String agencyName;
  final String taskId;

  const GeotagCameraEntryPage({
    super.key,
    required this.officerName,
    required this.agencyName,
    required this.taskId,
  });

  @override
  State<GeotagCameraEntryPage> createState() => _GeotagCameraEntryPageState();
}

class _GeotagCameraEntryPageState extends State<GeotagCameraEntryPage> {
  CameraController? _cameraController;
  GeotagCameraController? _geotagController;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false, // Bukti foto tidak butuh audio
      );

      await controller.initialize();

      // Baru daftarkan ke DI SETELAH controller siap - repository yang
      // dibuat di sini akan memegang instance controller yang valid.
      registerCameraSession(controller);

      final geotagController = GeotagCameraController(
        validateLocationIntegrity: sl<ValidateLocationIntegrity>(),
        captureGeotaggedPhoto: sl<CaptureGeotaggedPhoto>(),
        taskId: widget.taskId,
      );

      if (!mounted) {
        // Widget sudah di-dispose sebelum inisialisasi selesai (mis.
        // user menekan back cepat) - bersihkan langsung agar tidak leak.
        geotagController.dispose();
        await controller.dispose();
        unregisterCameraSession();
        return;
      }

      setState(() {
        _cameraController = controller;
        _geotagController = geotagController;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _initError = 'Kamera tidak dapat diakses. Periksa izin kamera.');
      }
    }
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography, color: Colors.white54, size: 48),
                const SizedBox(height: 16),
                Text(_initError!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_cameraController == null || _geotagController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return GeotagCameraPage(
      cameraController: _cameraController!,
      geotagController: _geotagController!,
      officerName: widget.officerName,
      agencyName: widget.agencyName,
      taskId: widget.taskId,
    );
  }
}
