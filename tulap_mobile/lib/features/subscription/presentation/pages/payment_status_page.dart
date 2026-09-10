import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../../app/presentation/main_shell.dart';
import '../../domain/entities/payment_transaction_entity.dart';
import '../../domain/entities/payment_transaction_status.dart';
import '../controllers/payment_status_controller.dart';
import '../widgets/tula_suppressed_scope.dart';

/// Menutup PaymentStatusPage + PaymentMethodPage + PurchaseSummaryPage
/// sekaligus, kembali ke SubscriptionPage - stack navigasi checkout
/// SELALU tepat 3 layar (Bagian 39: Plan Folder Carousel TIDAK dirombak,
/// jadi tidak ada named route yang bisa dituju langsung).
void _popBackToPlanSelection(BuildContext context) {
  final nav = Navigator.of(context);
  var pops = 0;
  while (nav.canPop() && pops < 3) {
    nav.pop();
    pops++;
  }
}

/// PaymentStatusPage
/// ----------------------------------------------------------------------
/// SATU halaman yang merender QRIS/VA + SEMUA state pembayaran (Menunggu,
/// Berhasil, Gagal, Kedaluwarsa - Bagian 12, 15, 25, 26, 27, 28 instruksi
/// payment) berdasarkan `PaymentTransactionEntity.status` yang datang
/// dari backend. Status di layar ini TIDAK PERNAH ditentukan client -
/// selalu dari PaymentStatusController yang membaca backend (Bagian 17 -
/// "Webhook Adalah Source of Truth"; menekan tombol "Saya sudah bayar"
/// TIDAK ADA di sini SENGAJA, lihat Bagian 63 - "Do Not").
/// ----------------------------------------------------------------------
class PaymentStatusPage extends StatelessWidget {
  final PaymentTransactionEntity transaction;
  const PaymentStatusPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return TulaSuppressedScope(
      child: ChangeNotifierProvider<PaymentStatusController>(
        create: (_) => PaymentStatusController(
          checkPaymentStatus: sl(),
          transaction: transaction,
        ),
        child: PopScope(
          // Transaksi PENDING tidak boleh ditinggalkan lewat swipe-back tanpa
          // sadar (Bagian 51 - Tula tidak boleh mengganggu, begitu juga
          // navigasi tidak sengaja) - back button tetap berfungsi lewat AppBar.
          canPop: true,
          child: const _PaymentStatusView(),
        ),
      ),
    );
  }
}

class _PaymentStatusView extends StatelessWidget {
  const _PaymentStatusView();

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final controller = context.watch<PaymentStatusController>();
    final tx = controller.transaction;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_titleFor(tx.status)),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: switch (tx.status) {
          PaymentTransactionStatus.paid => _SuccessView(tx: tx),
          PaymentTransactionStatus.failed => _FailedView(tx: tx),
          PaymentTransactionStatus.expired => _ExpiredView(tx: tx),
          PaymentTransactionStatus.cancelled => _ExpiredView(
            tx: tx,
            isCancelled: true,
          ),
          _ => _PendingView(tx: tx, controller: controller),
        },
      ),
    );
  }

  String _titleFor(PaymentTransactionStatus status) => switch (status) {
    PaymentTransactionStatus.paid => 'Pembayaran Berhasil',
    PaymentTransactionStatus.failed => 'Pembayaran Belum Berhasil',
    PaymentTransactionStatus.expired => 'Pembayaran Kedaluwarsa',
    PaymentTransactionStatus.cancelled => 'Pembayaran Dibatalkan',
    _ => 'Menunggu Pembayaran',
  };
}

// ================================================================
// PENDING - QRIS atau VA, tergantung paymentMethod (Bagian 12 & 15).
// ================================================================
class _PendingView extends StatelessWidget {
  final PaymentTransactionEntity tx;
  final PaymentStatusController controller;
  const _PendingView({required this.tx, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final isQris = tx.paymentMethod.name == 'qris';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Text(
                  AppDateFormatter.formatRupiah(tx.amount),
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (isQris) _QrisContent(tx: tx) else _VaContent(tx: tx),
                const SizedBox(height: AppSpacing.lg),
                if (tx.expiresAt != null) ...[
                  Text(
                    'Batas Pembayaran',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppDateFormatter.formatFullDateTime(tx.expiresAt!),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _StatusBadge(
                  label: 'Menunggu Pembayaran',
                  color: colors.warning,
                  soft: colors.warningSoft,
                ),
              ],
            ),
          ),
          if (controller.lastCheckFailed) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tidak dapat memeriksa pembayaran saat ini. Periksa kembali saat koneksi tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: controller.isChecking
                  ? null
                  : () => controller.refresh(),
              child: controller.isChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Cek Status Pembayaran'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrisContent extends StatelessWidget {
  final PaymentTransactionEntity tx;
  const _QrisContent({required this.tx});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    if (tx.qrString == null || tx.qrString!.isEmpty) {
      return Text(
        'QR pembayaran sedang disiapkan...',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: colors.textSecondary,
        ),
      );
    }

    return Semantics(
      label:
          'Kode QRIS untuk pembayaran ${AppDateFormatter.formatRupiah(tx.amount)}',
      image: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              border: Border.all(color: colors.border),
            ),
            child: QrImageView(
              data: tx.qrString!,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Scan QRIS menggunakan aplikasi bank atau e-wallet yang mendukung QRIS.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.5,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VaContent extends StatelessWidget {
  final PaymentTransactionEntity tx;
  const _VaContent({required this.tx});

  Future<void> _copy(BuildContext context) async {
    if (tx.vaNumber == null) return;
    await Clipboard.setData(ClipboardData(text: tx.vaNumber!.trim()));
    HapticFeedback.lightImpact();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nomor Virtual Account disalin')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bank / Channel',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          (tx.vaBank ?? '-').toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Nomor Virtual Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          tx.vaNumber ?? '-',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Salin Nomor VA'),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color soft;
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SUCCESS (Bagian 25) - tenang, tidak berlebihan (Bagian 50).
// ================================================================
class _SuccessView extends StatefulWidget {
  final PaymentTransactionEntity tx;
  const _SuccessView({required this.tx});

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    HapticFeedback.mediumImpact();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutBack,
              ),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: colors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: colors.success,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Pembayaran Berhasil',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_planDisplayName(widget.tx)} telah aktif.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                  );
                },
                child: Text('Mulai Gunakan ${_planDisplayName(widget.tx)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _planDisplayName(PaymentTransactionEntity tx) =>
      switch (tx.planCode.name) {
        'basic' => 'Basic',
        'pro' => 'Tulap Pro',
        'proPlus' => 'Tulap Pro+',
        _ => 'Paket Tulap',
      };
}

// ================================================================
// FAILED (Bagian 27) - tidak menyalahkan user.
// ================================================================
class _FailedView extends StatelessWidget {
  final PaymentTransactionEntity tx;
  const _FailedView({required this.tx});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, color: colors.danger, size: 40),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Pembayaran Belum Berhasil',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada perubahan pada paket Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Coba Lagi'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => _popBackToPlanSelection(context),
              child: const Text('Kembali ke Paket'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// EXPIRED / CANCELLED (Bagian 28) - buat pembayaran baru.
// ================================================================
class _ExpiredView extends StatelessWidget {
  final PaymentTransactionEntity tx;
  final bool isCancelled;
  const _ExpiredView({required this.tx, this.isCancelled = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colors.warningSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: colors.warning,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isCancelled ? 'Pembayaran Dibatalkan' : 'Pembayaran Kedaluwarsa',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Buat pembayaran baru untuk melanjutkan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Buat Pembayaran Baru'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
