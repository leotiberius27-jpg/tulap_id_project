import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/receipt_scanner_controller.dart';
import '../widgets/receipt_review_sheet.dart';

/// ReceiptScannerPage
/// ----------------------------------------------------------------------
/// Alur: Scan Nota -> Kamera -> OCR -> Review (bottom sheet) -> Confirm
/// (Bagian 9 spesifikasi). Halaman ini sengaja TIDAK full-screen seperti
/// GeotagCameraPage - nota adalah dokumen datar yang lebih nyaman
/// difoto dengan guide framing sederhana, bukan watermark live overlay.
/// ----------------------------------------------------------------------
class ReceiptScannerPage extends StatelessWidget {
  final CameraController cameraController;

  const ReceiptScannerPage({super.key, required this.cameraController});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptScannerController>(
      builder: (context, controller, _) {
        final state = controller.state;

        // Begitu status reviewing, tampilkan Review Sheet secara modal
        // di atas live camera - user masih bisa melihat konteks kamera
        // di belakang sheet.
        if (state.status == ReceiptScanStatus.reviewing ||
            state.status == ReceiptScanStatus.saving) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.isCurrent == true) {
              _showReviewSheet(context, controller);
            }
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(child: CameraPreview(cameraController)),

              // Frame guide sederhana untuk membantu user mengambil
              // foto nota yang rata & terbaca OCR
              const Center(
                child: _ReceiptFrameGuide(),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      const Text(
                        'Scan Nota',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40), // Penyeimbang tombol back
                    ],
                  ),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 32,
                child: Center(
                  child: GestureDetector(
                    onTap: state.status == ReceiptScanStatus.scanning
                        ? null
                        : controller.captureAndScan,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white.withOpacity(0.25),
                      ),
                      child: state.status == ReceiptScanStatus.scanning
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              if (state.status == ReceiptScanStatus.error)
                _ErrorBanner(message: state.errorMessage ?? 'Nominal kurang jelas, mohon periksa.'),
            ],
          ),
        );
      },
    );
  }

  void _showReviewSheet(BuildContext context, ReceiptScannerController controller) {
    final draft = controller.state.draft;
    if (draft == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ReceiptReviewSheet(
        draft: draft,
        isSaving: controller.state.status == ReceiptScanStatus.saving,
        onSave: ({
          required vendorName,
          required transactionDate,
          required totalAmount,
          required category,
          taxAmount,
          receiptNumber,
        }) async {
          final result = await controller.confirmSave(
            vendorName: vendorName,
            transactionDate: transactionDate,
            totalAmount: totalAmount,
            category: category,
            taxAmount: taxAmount,
            receiptNumber: receiptNumber,
          );

          if (!context.mounted) return;

          if (result.isSuccess) {
            Navigator.of(context).pop(); // Tutup sheet
            Navigator.of(context).pop(result.savedNote); // Kembali ke Detail Tugas
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.errorMessage ?? 'Nota belum berhasil disimpan.')),
            );
          }
        },
      ),
    );
  }
}

class _ReceiptFrameGuide extends StatelessWidget {
  const _ReceiptFrameGuide();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 360,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: const Center(
        child: Text(
          'Posisikan nota di dalam bingkai',
          style: TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 90,
      left: AppSpacing.base,
      right: AppSpacing.base,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Text(message, style: AppTypography.small.copyWith(color: AppColors.danger)),
      ),
    );
  }
}
