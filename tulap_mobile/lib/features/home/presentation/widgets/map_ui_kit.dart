import 'package:flutter/material.dart';
import '../theme/map_palette.dart';

/// Search bar mengambang bergaya aplikasi navigasi (putih, bayangan
/// lembut, ikon kaca pembesar teal) - dipakai bersama oleh halaman Peta
/// Sebaran Lokasi & halaman Detail Lokasi supaya konsisten.
class MapFloatingSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onTap;

  const MapFloatingSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Cari nama lokasi kegiatan...',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: MapPalette.deep, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onTap: onTap,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hintText,
                  hintStyle: const TextStyle(color: MapPalette.textSecondary),
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: MapPalette.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18, color: MapPalette.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tombol aksi bulat mengambang putih dengan ikon teal - dipakai di atas
/// peta (kembali, lokasi saya, ganti jenis peta, dst).
class MapCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? iconColor;

  const MapCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: const CircleBorder(),
        color: Colors.white,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icon, size: 20, color: iconColor ?? MapPalette.deep),
          ),
        ),
      ),
    );
  }
}

/// Chip status kegiatan (Sedang Berjalan / Selesai / dll) dengan titik
/// warna - dipakai di kartu carousel Beranda & sheet detail lokasi.
class LocationStatusChip extends StatelessWidget {
  final String status;

  const LocationStatusChip({super.key, required this.status});

  static String labelFor(String status) {
    switch (status) {
      case 'ONGOING':
        return 'Sedang Berjalan';
      case 'PENDING_VERIFICATION':
        return 'Menunggu Verifikasi';
      case 'REVISION_NEEDED':
        return 'Perlu Diperbaiki';
      case 'VERIFIED':
        return 'Disetujui';
      case 'REJECTED':
        return 'Ditolak';
      case 'COMPLETED':
        return 'Selesai';
      case 'DRAFT':
      default:
        return 'Belum Dimulai';
    }
  }

  static Color colorFor(String status) {
    switch (status) {
      case 'ONGOING':
        return MapPalette.accent;
      case 'PENDING_VERIFICATION':
      case 'REVISION_NEEDED':
        return const Color(0xFFF59E0B);
      case 'REJECTED':
        return const Color(0xFFDC2626);
      case 'VERIFIED':
      case 'COMPLETED':
        return MapPalette.statusDone;
      default:
        return MapPalette.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            labelFor(status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
