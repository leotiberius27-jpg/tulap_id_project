import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

/// WatermarkOverlay
/// ----------------------------------------------------------------------
/// Overlay semi-transparent yang tampil di atas live camera view,
/// menampilkan data yang akan "dicap" ke foto: nama petugas, instansi,
/// ID Tugas, koordinat, alamat, tanggal & jam server (Bagian 8).
///
/// Widget ini HANYA untuk preview visual real-time di layar - proses
/// "burn-in" watermark ke file gambar sesungguhnya dilakukan terpisah
/// di data layer (mis. lewat package image compositing) agar watermark
/// permanen menempel di file, bukan sekadar overlay UI yang hilang
/// setelah screenshot.
/// ----------------------------------------------------------------------
class WatermarkOverlay extends StatelessWidget {
  final String officerName;
  final String agencyName;
  final String taskId;
  final double? latitude;
  final double? longitude;
  final String? address;

  const WatermarkOverlay({
    super.key,
    required this.officerName,
    required this.agencyName,
    required this.taskId,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormatted = DateFormat('d MMM yyyy · HH:mm:ss', 'id_ID').format(now);

    return Positioned(
      left: AppSpacing.base,
      right: AppSpacing.base,
      bottom: 140, // Di atas tombol capture, tidak menutupinya
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tulap.id',
              style: AppTypography.small.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            _WatermarkLine('$officerName · $agencyName'),
            _WatermarkLine('Tugas #$taskId'),
            _WatermarkLine(
              latitude != null && longitude != null
                  ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
                  : 'Mengambil koordinat…',
            ),
            if (address != null) _WatermarkLine(address!),
            _WatermarkLine(dateFormatted),
          ],
        ),
      ),
    );
  }
}

class _WatermarkLine extends StatelessWidget {
  final String text;
  const _WatermarkLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        height: 1.4,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
