import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tulap_mobile/core/theme/app_theme.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';
import 'package:tulap_mobile/features/evidence_verification/domain/entities/evidence_verification_result.dart';
import 'package:tulap_mobile/features/evidence_verification/domain/usecases/verify_evidence_integrity.dart';
import 'package:tulap_mobile/features/evidence_verification/presentation/widgets/verification_checklist_tile.dart';
import 'package:tulap_mobile/features/evidence_verification/presentation/pages/evidence_technical_details_page.dart';

class EvidenceVerificationPage extends StatefulWidget {
  final GeotagPhotoEntity photo;
  final TaskEntity? task;
  final AuthUserEntity? user;
  final EvidenceVerificationResult? initialResult;

  const EvidenceVerificationPage({
    super.key,
    required this.photo,
    this.task,
    this.user,
    this.initialResult,
  });

  @override
  State<EvidenceVerificationPage> createState() =>
      _EvidenceVerificationPageState();
}

class _EvidenceVerificationPageState extends State<EvidenceVerificationPage> {
  late Future<EvidenceVerificationResult> _verificationFuture;

  @override
  void initState() {
    super.initState();
    if (widget.initialResult != null) {
      _verificationFuture = Future.value(widget.initialResult);
    } else {
      _runVerification();
    }
  }

  void _runVerification() {
    final useCase = GetIt.I<VerifyEvidenceIntegrity>();
    _verificationFuture = useCase.call(
      photo: widget.photo,
      task: widget.task,
      user: widget.user,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Bukti Digital'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Ulangi Verifikasi',
            onPressed: () => setState(_runVerification),
          ),
        ],
      ),
      body: FutureBuilder<EvidenceVerificationResult>(
        future: _verificationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF006EE6),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Menghitung Checksum & Mengaudit Bukti…',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Gagal Menjalankan Verifikasi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(_runVerification),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final result = snapshot.data!;
          final df = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.base),
            children: [
              // 1. Status Banner Utama
              _buildHeaderBanner(context, result),
              const SizedBox(height: AppSpacing.lg),

              // 2. Section Label
              Text(
                'HASIL PEMERIKSAAN INTEGRITAS',
                style: AppTypography.sectionLabel,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Tile A: File Integrity
              VerificationChecklistTile(
                title: 'Integritas File Foto (SHA-256)',
                subtitle: result.isFinalHashValid
                    ? 'Hash file cocok dengan database bukti resmi (Untampered)'
                    : 'Peringatan: Hash file TIDAK cocok! File terindikasi telah diubah.',
                state: result.isFinalHashValid
                    ? CheckState.pass
                    : CheckState.fail,
              ),

              // Tile B: Location & GPS
              VerificationChecklistTile(
                title: 'Metadata Lokasi Geografis',
                subtitle: result.hasValidLocation
                    ? '${result.address ?? result.plusCode}\nGPS ±${result.gpsAccuracyMeters.round()} m'
                    : 'Koordinat GPS tidak valid atau tidak terekam.',
                state: result.hasValidLocation
                    ? (result.gpsAccuracyMeters <= 25.0
                        ? CheckState.pass
                        : CheckState.warning)
                    : CheckState.fail,
              ),

              // Tile C: Mock Location
              VerificationChecklistTile(
                title: 'Deteksi Lokasi Palsu (Fake GPS)',
                subtitle: !result.isMockLocationDetected
                    ? 'Lokasi otentik dari sensor perangkat (Tidak terdeteksi mock GPS)'
                    : 'Terdeteksi penyedia lokasi palsu (Mock Location Provider)',
                state: !result.isMockLocationDetected
                    ? CheckState.pass
                    : CheckState.fail,
              ),

              // Tile D: Waktu & Provensi
              VerificationChecklistTile(
                title: 'Waktu & Provensi Bukti',
                subtitle:
                    'Waktu: ${df.format(result.deviceTimestamp ?? result.serverTimestamp)} WIT\nTimestamp Server: ${df.format(result.serverTimestamp)} WIT',
                state: CheckState.pass,
              ),

              // Tile E: Sumber Kamera & Perangkat
              VerificationChecklistTile(
                title: 'Sumber & Keamanan Perangkat',
                subtitle: !result.isRootedDeviceDetected
                    ? 'Diambil langsung via Kamera Resmi Tulap.id'
                    : 'Peringatan: Perangkat terdeteksi Root / Jailbreak',
                state: !result.isRootedDeviceDetected
                    ? CheckState.pass
                    : CheckState.fail,
              ),

              // Tile F: Activity Binding
              VerificationChecklistTile(
                title: 'Keterkaitan Tugas Lapangan',
                subtitle: result.isActivityBound
                    ? '${result.taskTitle}\nPetugas: ${result.officerName} • ${result.agencyName}'
                    : 'Bukti tidak terikat pada kegiatan yang sesuai.',
                state: result.isActivityBound
                    ? CheckState.pass
                    : CheckState.warning,
              ),

              // Tile G: Cloud Sync
              VerificationChecklistTile(
                title: 'Status Sinkronisasi Cloud',
                subtitle: result.isSynced
                    ? 'Tersinkronisasi & terverifikasi dengan server pusat'
                    : 'Verifikasi Lokal Selesai • Menunggu koneksi internet untuk sync',
                state: result.isSynced
                    ? CheckState.pass
                    : CheckState.warning,
              ),

              const SizedBox(height: AppSpacing.lg),

              // 3. Tombol Aksi Verifikasi
              ElevatedButton.icon(
                icon: const Icon(Icons.code_rounded),
                label: const Text('Lihat Detail Teknis & Kriptografi'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: const Color(0xFF006EE6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EvidenceTechnicalDetailsPage(result: result),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Tampilkan QR Verifikasi On-Demand'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                onPressed: () => _showQrModal(context, result),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderBanner(
    BuildContext context,
    EvidenceVerificationResult result,
  ) {
    final Color gradientStart;
    final Color gradientEnd;
    final IconData icon;

    switch (result.overallStatus) {
      case EvidenceVerificationStatus.verified:
        gradientStart = const Color(0xFF059669);
        gradientEnd = const Color(0xFF10B981);
        icon = Icons.verified_rounded;
        break;
      case EvidenceVerificationStatus.reviewRequired:
        gradientStart = const Color(0xFFD97706);
        gradientEnd = const Color(0xFFF59E0B);
        icon = Icons.warning_amber_rounded;
        break;
      case EvidenceVerificationStatus.integrityFailed:
        gradientStart = const Color(0xFFDC2626);
        gradientEnd = const Color(0xFFEF4444);
        icon = Icons.gpp_bad_rounded;
        break;
      case EvidenceVerificationStatus.recorded:
      case EvidenceVerificationStatus.synced:
        gradientStart = const Color(0xFF0284C7);
        gradientEnd = const Color(0xFF0EA5E9);
        icon = Icons.lock_clock_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.statusBadgeTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${result.shortEvidenceId}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.isFullyVerified
                ? 'Seluruh parameter integritas kriptografi, geolokasi, dan kepemilikan tugas telah terverifikasi secara valid.'
                : (result.isIntegrityFailed
                    ? 'Integritas bukti digital bermasalah. Checksum file atau indikator keamanan tidak valid.'
                    : 'Bukti tersimpan secara aman di penyimpanan lokal perangkat. Verifikasi penuh akan dikonfirmasi setelah tersinkronisasi ke cloud.'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showQrModal(BuildContext context, EvidenceVerificationResult result) {
    final verificationUrl =
        'https://verify.tulap.id/e/${result.shortEvidenceId}?t=${result.taskId}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'QR Verifikasi Bukti Lapangan',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pindai untuk memverifikasi keaslian bukti via portal Tulap.id',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              // QR Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: verificationUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0F172A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                result.shortEvidenceId,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Tutup'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
