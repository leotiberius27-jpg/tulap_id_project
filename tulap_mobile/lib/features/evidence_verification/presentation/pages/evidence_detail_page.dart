import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/map/map_launcher_service.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../widgets/verification_status_badge.dart';
import 'evidence_verification_page.dart';

/// EvidenceDetailPage
/// ----------------------------------------------------------------------
/// Halaman Detail Bukti Digital (Human-Readable Evidence Detail):
/// - Membaca langsung dari Evidence Record sebagai sumber kebenaran (source of truth).
/// - Menggunakan koordinat asli dan timestamp asli (bukan GPS/waktu saat ini).
/// - Bagian: Informasi Kegiatan, Lokasi & Aksi Google Maps, Metadata Bukti,
///   Snapshot Petugas, Catatan/Keterangan Pengguna, dan Bagian Informasi Teknis.
/// ----------------------------------------------------------------------
class EvidenceDetailPage extends StatelessWidget {
  final GeotagPhotoEntity photo;
  final TaskEntity? task;
  final AuthUserEntity? user;

  const EvidenceDetailPage({
    super.key,
    required this.photo,
    this.task,
    this.user,
  });

  Future<void> _openGoogleMaps(BuildContext context) async {
    final mapService = sl<MapLauncherService>();
    final success = await mapService.openGoogleMaps(
      latitude: photo.latitude,
      longitude: photo.longitude,
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi tidak dapat dibuka.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String formattedDate;
    try {
      final df = DateFormat('dd MMMM yyyy • HH:mm', 'id_ID');
      formattedDate = '${df.format(photo.deviceTimestamp ?? photo.serverTimestamp)} WIT';
    } catch (_) {
      formattedDate = (photo.deviceTimestamp ?? photo.serverTimestamp).toIso8601String();
    }

    final file = File(photo.localFilePath);
    final hasLocalFile = file.existsSync();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Bukti'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: VerificationStatusBadge(
                status: photo.verificationStatus,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Media Preview Card / Header
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 220,
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    hasLocalFile
                        ? Image.file(
                            file,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) =>
                                _buildFallbackImage(),
                          )
                        : (photo.localFilePath.startsWith('http')
                            ? Image.network(
                                photo.localFilePath,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, stack) =>
                                    _buildFallbackImage(),
                              )
                            : _buildFallbackImage()),

                    if (photo.isVideo)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. INFORMASI KEGIATAN
            _buildSectionCard(
              context,
              title: 'INFORMASI KEGIATAN',
              icon: Icons.assignment_outlined,
              children: [
                _buildInfoRow(
                  'Kegiatan',
                  task?.taskName ?? photo.caption ?? 'Monitoring Lapangan',
                  isBold: true,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  'Waktu Pengambilan',
                  formattedDate,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. LOKASI
            _buildSectionCard(
              context,
              title: 'LOKASI',
              icon: Icons.location_on_outlined,
              children: [
                _buildInfoRow(
                  'Alamat',
                  photo.address ?? 'Mimika, Papua Tengah',
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  'Koordinat',
                  '${photo.latitude.toStringAsFixed(6)}, ${photo.longitude.toStringAsFixed(6)}',
                  fontFamily: 'monospace',
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  'Akurasi GPS',
                  '±${photo.gpsAccuracyMeters.round()} m',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openGoogleMaps(context),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Buka di Google Maps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF006EE6),
                    side: const BorderSide(color: Color(0xFF006EE6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. BUKTI
            _buildSectionCard(
              context,
              title: 'BUKTI',
              icon: Icons.verified_outlined,
              children: [
                _buildInfoRow(
                  'ID Bukti',
                  photo.displayEvidenceId,
                  fontFamily: 'monospace',
                  isBold: true,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  'Jenis Media',
                  photo.isVideo ? 'Video (${photo.durationSeconds}s)' : 'Foto',
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  'Status Sinkronisasi',
                  photo.syncStatus,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5. PETUGAS
            _buildSectionCard(
              context,
              title: 'PETUGAS',
              icon: Icons.person_outline_rounded,
              children: [
                _buildInfoRow(
                  'Nama',
                  user?.fullName ?? 'Petugas Lapangan',
                  isBold: true,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  'Instansi / Role',
                  user?.role ?? 'Inspektur Lapangan',
                ),
              ],
            ),

            if (photo.caption != null &&
                photo.caption!.isNotEmpty &&
                photo.caption != task?.taskName &&
                task != null) ...[
              const SizedBox(height: 12),
              _buildSectionCard(
                context,
                title: 'KETERANGAN',
                icon: Icons.notes_rounded,
                children: [
                  Text(
                    photo.caption!,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // 6. INFORMASI TEKNIS (Collapsed)
            Card(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: ExpansionTile(
                leading: const Icon(
                  Icons.terminal_rounded,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
                title: const Text(
                  'Informasi Teknis',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _buildTechnicalRow('Evidence UUID', photo.id),
                  const Divider(height: 12),
                  _buildTechnicalRow(
                    'Original SHA-256',
                    photo.originalHash ?? photo.integrityHash,
                  ),
                  const Divider(height: 12),
                  _buildTechnicalRow(
                    'Final SHA-256',
                    photo.finalHash ?? photo.integrityHash,
                  ),
                  const Divider(height: 12),
                  _buildTechnicalRow(
                    'Waktu Server',
                    photo.serverTimestamp.toIso8601String(),
                  ),
                  const Divider(height: 12),
                  _buildTechnicalRow(
                    'Mock Location',
                    photo.isMockLocationDetected
                        ? 'Terdeteksi Mock'
                        : 'Aman (Hardware GPS)',
                  ),
                  const Divider(height: 12),
                  _buildTechnicalRow(
                    'Rooted Device',
                    photo.isRootedDeviceDetected
                        ? 'Terdeteksi Root/Jailbreak'
                        : 'Aman (Normal)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 7. Tombol Verifikasi Forensik
            ElevatedButton.icon(
              icon: const Icon(Icons.shield_outlined, size: 20),
              label: const Text('Verifikasi Integritas Bukti'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006EE6),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EvidenceVerificationPage(
                      photo: photo,
                      task: task,
                      user: user,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF006EE6)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    String? fontFamily,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontFamily: fontFamily,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: Colors.black26,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_rounded, color: Colors.white38, size: 48),
          SizedBox(height: 8),
          Text(
            'Pratinjau gambar tidak tersedia secara lokal',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
