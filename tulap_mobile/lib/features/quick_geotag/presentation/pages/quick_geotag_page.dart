import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/quick_geotag_controller.dart';

/// QuickGeotagPage
/// ----------------------------------------------------------------------
/// Halaman "Foto + Kunci GPS": satu tombol untuk memotret via kamera
/// hardware, lalu koordinat (lat, lng) terkini otomatis dikunci dan
/// ditampilkan bersama pratinjau foto.
/// ----------------------------------------------------------------------
class QuickGeotagPage extends StatelessWidget {
  const QuickGeotagPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuickGeotagController()..start(),
      child: const _QuickGeotagView(),
    );
  }
}

class _QuickGeotagView extends StatelessWidget {
  const _QuickGeotagView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<QuickGeotagController>();
    final colors = context.tulapColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Foto + Kunci GPS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            _LiveGpsCard(controller: c),
            const SizedBox(height: AppSpacing.base),
            if (c.errorMessage != null) ...[
              _ErrorBanner(
                message: c.errorMessage!,
                onRetry: c.status == QuickGeotagStatus.error ? c.start : null,
              ),
              const SizedBox(height: AppSpacing.base),
            ],
            _PhotoPreview(result: c.result),
            if (c.result != null) ...[
              const SizedBox(height: AppSpacing.base),
              _LockedCoordinateCard(result: c.result!),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.base,
        ),
        child: SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: c.status == QuickGeotagStatus.ready && !c.isBusy
                ? c.captureAndLock
                : null,
            icon: c.isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.photo_camera_rounded),
            label: Text(_buttonLabel(c)),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              textStyle: AppTypography.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buttonLabel(QuickGeotagController c) {
    switch (c.status) {
      case QuickGeotagStatus.capturing:
        return 'Membuka Kamera...';
      case QuickGeotagStatus.locking:
        return 'Mengunci GPS...';
      case QuickGeotagStatus.initializing:
        return 'Menyiapkan GPS...';
      default:
        return c.result == null ? 'Ambil Foto' : 'Ambil Foto Ulang';
    }
  }
}

class _LiveGpsCard extends StatelessWidget {
  final QuickGeotagController controller;
  const _LiveGpsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final Position? pos = controller.livePosition;
    final acc = pos?.accuracy;

    final Color dot;
    final String label;
    if (pos == null) {
      dot = colors.warning;
      label = 'Mencari sinyal GPS...';
    } else if (acc! <= 15) {
      dot = colors.success;
      label = 'GPS Akurat (±${acc.round()} m)';
    } else if (acc <= 50) {
      dot = colors.warning;
      label = 'GPS Cukup (±${acc.round()} m)';
    } else {
      dot = colors.danger;
      label = 'GPS Lemah (±${acc.round()} m)';
    }

    return _Card(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                )),
                const SizedBox(height: 2),
                Text(
                  pos == null
                      ? 'Koordinat langsung akan muncul di sini'
                      : 'Langsung: ${pos.latitude.toStringAsFixed(6)}, '
                          '${pos.longitude.toStringAsFixed(6)}',
                  style: AppTypography.small.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final LockedGeotagPhoto? result;
  const _PhotoPreview({required this.result});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: result == null
            ? Container(
                color: colors.surface,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        size: 48, color: colors.textSecondary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Belum ada foto',
                      style: AppTypography.bodySecondary
                          .copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              )
            : Image.file(result!.file, fit: BoxFit.cover),
      ),
    );
  }
}

class _LockedCoordinateCard extends StatelessWidget {
  final LockedGeotagPhoto result;
  const _LockedCoordinateCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final mono = AppTypography.body.copyWith(
      color: colors.textPrimary,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_rounded, size: 18, color: colors.success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Koordinat Terkunci',
                  style: AppTypography.sectionTitle
                      .copyWith(color: colors.textPrimary),
                ),
              ),
              IconButton(
                tooltip: 'Salin koordinat',
                icon: const Icon(Icons.copy_rounded, size: 20),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: result.coordinateText),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Koordinat disalin')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _Row('Latitude', result.latitude.toStringAsFixed(6), mono),
          _Row('Longitude', result.longitude.toStringAsFixed(6), mono),
          _Row('Akurasi', '±${result.accuracy.toStringAsFixed(1)} m', mono),
          if (result.altitude != null)
            _Row('Ketinggian', '${result.altitude!.toStringAsFixed(1)} m', mono),
          _Row(
            'Waktu kunci',
            DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID')
                .format(result.lockedAt),
            mono,
          ),
          _Row('Sumber', result.source == 'GPS_FRESH'
              ? 'Fix GPS baru'
              : 'Stream GPS terakhir', mono),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle valueStyle;
  const _Row(this.label, this.value, this.valueStyle);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: AppTypography.bodySecondary
                  .copyWith(color: context.tulapColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.small.copyWith(color: colors.textPrimary),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}
