import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/expense_note_entity.dart';
import '../controllers/receipt_scanner_controller.dart';
import '../widgets/receipt_review_sheet.dart';
import 'manual_expense_page.dart';

/// ReceiptScannerPage
/// ----------------------------------------------------------------------
/// Scanner Kamera Khusus Dokumen Nota:
/// - Framing guide persegi panjang dokumen
/// - Tombol senter / flash
/// - Tombol Import dari Galeri
/// - Tombol Input Manual tanpa nota fisik
/// ----------------------------------------------------------------------
class ReceiptScannerPage extends StatelessWidget {
  final CameraController cameraController;

  const ReceiptScannerPage({super.key, required this.cameraController});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptScannerController>(
      builder: (context, controller, _) {
        final state = controller.state;

        if (state.status == ReceiptScanStatus.reviewing ||
            state.status == ReceiptScanStatus.saving) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.isCurrent == true) {
              _showReviewSheet(context, controller);
            }
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            var cameraRatio = cameraController.value.aspectRatio;
            if (cameraRatio > 1.0) {
              cameraRatio = 1.0 / cameraRatio;
            }

            final screenRatio = screenWidth / screenHeight;
            final scale = screenRatio < cameraRatio
                ? (cameraRatio / screenRatio)
                : (screenRatio / cameraRatio);

            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  // Fullscreen Edge-to-Edge Camera Preview
                  Center(
                    child: ClipRect(
                      child: SizedBox(
                        width: screenWidth,
                        height: screenHeight,
                        child: Center(
                          child: Transform.scale(
                            scale: scale,
                            child: AspectRatio(
                              aspectRatio: cameraRatio,
                              child: CameraPreview(cameraController),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tap to Focus & Exposure Area
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        try {
                          final offset = details.localPosition;
                          final x = (offset.dx / screenWidth).clamp(0.0, 1.0);
                          final y = (offset.dy / screenHeight).clamp(0.0, 1.0);
                          cameraController.setFocusPoint(Offset(x, y));
                          cameraController.setExposurePoint(Offset(x, y));
                        } catch (_) {}
                      },
                    ),
                  ),

                  // Semi-transparent overlay with document crop window
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: _DocumentScanOverlay(),
                    ),
                  ),

              // Header Bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back,
                        semanticLabel: 'Kembali',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      const Text(
                        'Scan Nota Pengeluaran',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      _CircleIconButton(
                        icon: state.isFlashOn ? Icons.flash_on : Icons.flash_off,
                        semanticLabel: 'Flash',
                        color: state.isFlashOn ? Colors.amber : Colors.white,
                        onTap: () => controller.toggleFlash(cameraController),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Controls Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 36,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.status == ReceiptScanStatus.scanning) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Membaca teks nota (OCR)...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Posisikan nota di dalam bingkai',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),
                    ],

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Tombol Galeri
                          _ActionButton(
                            icon: Icons.photo_library_rounded,
                            label: 'Galeri',
                            onTap: state.status == ReceiptScanStatus.scanning
                                ? null
                                : () => controller.importFromGalleryAndScan(),
                          ),

                          // Tombol Shutter
                          Semantics(
                            button: true,
                            label: 'Ambil foto nota',
                            enabled: state.status != ReceiptScanStatus.scanning,
                            child: GestureDetector(
                              onTap: state.status == ReceiptScanStatus.scanning
                                  ? null
                                  : () {
                                      HapticFeedback.mediumImpact();
                                      controller.captureAndScan();
                                    },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                child: state.status == ReceiptScanStatus.scanning
                                    ? const Padding(
                                        padding: EdgeInsets.all(22),
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Center(
                                        child: Container(
                                          width: 62,
                                          height: 62,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          // Tombol Manual
                          _ActionButton(
                            icon: Icons.edit_note_rounded,
                            label: 'Manual',
                            onTap: state.status == ReceiptScanStatus.scanning
                                ? null
                                : () async {
                                    final saved = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ManualExpensePage(
                                          taskId: controller.taskId,
                                        ),
                                      ),
                                    );
                                    if (context.mounted && saved != null) {
                                      Navigator.of(context).pop(saved);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (state.status == ReceiptScanStatus.error)
                _ErrorBanner(
                  message:
                      state.errorMessage ??
                      'Gagal membaca nota. Coba foto ulang.',
                ),
            ],
          ),
        );
      },
    );
  },
);
}

  void _showReviewSheet(
    BuildContext context,
    ReceiptScannerController controller,
  ) {
    final draft = controller.state.draft;
    if (draft == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) {
        return ReceiptReviewSheet(
          draft: draft,
          isSaving: controller.state.status == ReceiptScanStatus.saving,
          duplicateWarning: controller.state.duplicateWarning,
          onSave: ({
            required String vendorName,
            required DateTime transactionDate,
            String? transactionTime,
            required double totalAmount,
            required ExpenseCategoryEntity category,
            double? subtotal,
            double? taxAmount,
            double? discountAmount,
            double? serviceCharge,
            String? receiptNumber,
            String? paymentMethod,
            String? notes,
          }) async {
            final result = await controller.confirmSave(
              vendorName: vendorName,
              transactionDate: transactionDate,
              transactionTime: transactionTime,
              totalAmount: totalAmount,
              category: category,
              subtotal: subtotal,
              taxAmount: taxAmount,
              discountAmount: discountAmount,
              serviceCharge: serviceCharge,
              receiptNumber: receiptNumber,
              paymentMethod: paymentMethod,
              notes: notes,
            );

            if (context.mounted) {
              Navigator.of(context).pop(); // Tutup Review Sheet
              if (result.isSuccess) {
                Navigator.of(context).pop(result.savedNote); // Kembali ke Task Detail
              }
            }
          },
        );
      },
    ).whenComplete(() {
      if (controller.state.status == ReceiptScanStatus.reviewing) {
        controller.discardAndRescan();
      }
    });
  }
}

/// _DocumentScanOverlay
/// ----------------------------------------------------------------------
/// Bingkai pemandu ala Google Lens: area di luar bingkai digelapkan
/// (scrim) supaya jelas TIDAK ikut dibaca, dan garis pindai animasi naik
/// -turun di dalam bingkai memberi kesan "live scanning". Proporsi
/// bingkai (85% lebar x 58% tinggi, tengah) HARUS SAMA dengan
/// `ReceiptImageProcessor._cropWidthFraction/_cropHeightFraction` - sejak
/// perbaikan pipeline OCR, area inilah yang benar-benar dipotong &
/// dikirim ke OCR untuk hasil kamera langsung, bukan cuma dekorasi.
class _DocumentScanOverlay extends StatefulWidget {
  const _DocumentScanOverlay();

  @override
  State<_DocumentScanOverlay> createState() => _DocumentScanOverlayState();
}

class _DocumentScanOverlayState extends State<_DocumentScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * 0.85;
        final height = constraints.maxHeight * 0.58;
        final rect = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
          width: width,
          height: height,
        );

        return Stack(
          children: [
            // Scrim: gelapkan seluruh area DI LUAR bingkai - sejak crop
            // sungguhan diterapkan, ini menegaskan secara visual bahwa
            // area gelap memang tidak ikut terbaca OCR.
            Positioned.fill(
              child: CustomPaint(
                painter: _ScrimPainter(cutout: rect, radius: 16),
              ),
            ),
            Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Align(
                      alignment: Alignment(0, -1 + 2 * _controller.value),
                      child: Container(
                        height: 2.5,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.0),
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.7),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // 4 Corner brackets
                    Positioned(top: -2, left: -2, child: _CornerBracket(isTop: true, isLeft: true)),
                    Positioned(top: -2, right: -2, child: _CornerBracket(isTop: true, isLeft: false)),
                    Positioned(bottom: -2, left: -2, child: _CornerBracket(isTop: false, isLeft: true)),
                    Positioned(bottom: -2, right: -2, child: _CornerBracket(isTop: false, isLeft: false)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScrimPainter extends CustomPainter {
  final Rect cutout;
  final double radius;

  const _ScrimPainter({required this.cutout, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(cutout, Radius.circular(radius)));
    final scrimPath = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(scrimPath, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter oldDelegate) =>
      oldDelegate.cutout != cutout || oldDelegate.radius != radius;
}

class _CornerBracket extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerBracket({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final Color color;

  const _CircleIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.45),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
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
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
