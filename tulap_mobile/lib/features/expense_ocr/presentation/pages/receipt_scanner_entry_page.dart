import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../domain/repositories/expense_ocr_repository.dart';
import '../../domain/usecases/save_expense_note.dart';
import '../../domain/usecases/scan_receipt.dart';
import '../controllers/receipt_scanner_controller.dart';
import 'receipt_scanner_page.dart';

/// ReceiptScannerEntryPage
/// ----------------------------------------------------------------------
/// INI yang sebenarnya dipanggil lewat `Navigator.push` dari Detail
/// Tugas ("Scan Nota" quick action) - BUKAN ReceiptScannerPage
/// langsung. Mengikuti pola PERSIS GeotagCameraEntryPage: halaman ini
/// menangani seluruh siklus hidup yang butuh async & harus dibersihkan
/// dengan benar:
///
///   1. `availableCameras()` -> pilih kamera belakang -> inisialisasi
///      CameraController (async, perlu loading state).
///   2. `registerCameraSession(controller)` -> mendaftarkan
///      ExpenseOcrRepository & usecase terkait (ScanReceipt,
///      ConfirmAndSaveExpenseNote) ke service locator untuk sesi
///      kamera kali ini - fungsi yang sama yang sudah dipakai
///      GeotagCameraEntryPage, tidak perlu duplikasi.
///   3. Membuat ReceiptScannerController dari usecase yang baru
///      terdaftar, lalu merender ReceiptScannerPage yang sesungguhnya
///      di dalam ChangeNotifierProvider (ReceiptScannerPage sendiri
///      TIDAK membungkus Provider-nya seperti GeotagCameraPage,
///      sehingga entry page ini yang menyediakannya).
///   4. Saat halaman ditutup (dispose): controller di-dispose, kamera
///      dilepas, DAN `unregisterCameraSession()` dipanggil - mencegah
///      memory leak dan referensi ke CameraController yang sudah mati.
/// ----------------------------------------------------------------------
class ReceiptScannerEntryPage extends StatefulWidget {
  final String taskId;

  const ReceiptScannerEntryPage({super.key, required this.taskId});

  @override
  State<ReceiptScannerEntryPage> createState() =>
      _ReceiptScannerEntryPageState();
}

class _ReceiptScannerEntryPageState extends State<ReceiptScannerEntryPage> {
  CameraController? _cameraController;
  ReceiptScannerController? _receiptController;
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
        enableAudio: false, // Bukti nota tidak butuh audio
      );

      await controller.initialize();

      // Baru daftarkan ke DI SETELAH controller siap - repository yang
      // dibuat di sini akan memegang instance controller yang valid.
      registerCameraSession(controller);

      final receiptController = ReceiptScannerController(
        scanReceipt: sl<ScanReceipt>(),
        confirmAndSave: sl<ConfirmAndSaveExpenseNote>(),
        repository: sl<ExpenseOcrRepository>(),
        taskId: widget.taskId,
      );

      if (!mounted) {
        // Widget sudah di-dispose sebelum inisialisasi selesai (mis.
        // user menekan back cepat) - bersihkan langsung agar tidak leak.
        receiptController.dispose();
        await controller.dispose();
        unregisterCameraSession();
        return;
      }

      setState(() {
        _cameraController = controller;
        _receiptController = receiptController;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _initError = 'Kamera tidak dapat diakses. Periksa izin kamera.',
        );
      }
    }
  }

  @override
  void dispose() {
    _receiptController?.dispose();
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
                const Icon(
                  Icons.no_photography,
                  color: Colors.white54,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _initError!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
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

    if (_cameraController == null || _receiptController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return ChangeNotifierProvider<ReceiptScannerController>.value(
      value: _receiptController!,
      child: ReceiptScannerPage(cameraController: _cameraController!),
    );
  }
}
