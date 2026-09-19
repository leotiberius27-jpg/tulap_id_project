import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../data/firebase_email_auth_service.dart';
import '../data/live_location_repository.dart';
import '../data/live_location_tracking_service.dart';
import 'firebase_login_page.dart';

/// LiveTrackingPage
/// ----------------------------------------------------------------------
/// Layar "self-view" modul percobaan `firebase_live_tracking`: user yang
/// sudah login lewat Firebase (lihat FirebaseLoginPage) bisa
/// mulai/hentikan siaran posisi GPS-nya sendiri ke Firestore
/// (`live_locations/{uid}`) dan melihat titik terakhir yang tersimpan
/// secara real-time lewat `LiveLocationRepository.watchLocation()`.
///
/// Memakai `LiveLocationTrackingService.instance` (singleton app-wide),
/// BUKAN instance page-scoped sendiri - sebelumnya halaman ini membuat
/// instance privatnya sendiri, sehingga kalau tombol "Masuk dengan
/// Google" di layar login utama sudah menyalakan pelacakan lebih dulu
/// (lihat AuthRepositoryImpl._connectLiveTracking), status di halaman
/// ini tetap menampilkan "Pelacakan tidak aktif" - GPS-nya SUNGGUHAN
/// tetap berjalan (dua instance = dua stream GPS terpisah yang
/// keduanya menulis dokumen Firestore yang sama), hanya toggle/label di
/// UI ini yang keliru karena membaca state lokal yang tidak pernah
/// disinkronkan. Sekarang kedua jalur berbagi satu instance yang sama,
/// jadi statusnya selalu akurat dari mana pun tracking dimulai.
///
/// Konsekuensinya: `dispose()` TIDAK LAGI menghentikan tracking saat
/// halaman ini ditutup - itu perilaku yang salah untuk instance
/// bersama (pengguna produksi tidak boleh berhenti dilacak hanya
/// karena developer membuka lalu menutup halaman debug ini). Tracking
/// tetap berjalan di background sampai user menekan "Hentikan" secara
/// eksplisit atau logout.
/// ----------------------------------------------------------------------
class LiveTrackingPage extends StatefulWidget {
  final User user;
  const LiveTrackingPage({super.key, required this.user});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final _authService = FirebaseEmailAuthService();
  final _repository = LiveLocationRepository();
  final _trackingService = LiveLocationTrackingService.instance;

  bool _isTracking = LiveLocationTrackingService.instance.isTracking;
  bool _isBusy = false;

  Future<void> _toggleTracking() async {
    setState(() => _isBusy = true);
    try {
      if (_isTracking) {
        await _trackingService.stopTracking();
        setState(() => _isTracking = false);
      } else {
        await _trackingService.startTracking(widget.user.uid);
        setState(() => _isTracking = true);
      }
    } on LocationServiceDisabledException {
      _showMessage('Aktifkan layanan lokasi (GPS) perangkat terlebih dahulu.');
    } on PermissionDeniedException catch (e) {
      _showMessage(e.message ?? 'Izin lokasi ditolak.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isBusy = true);
    // Pakai widget.user.uid langsung (bukan clearRemote:true di
    // stopTracking()) - stopTracking() SELALU me-reset _activeUserId
    // internalnya ke null di akhir pemanggilan apa pun nilai
    // clearRemote-nya, jadi kalau user sempat menekan "Hentikan" secara
    // manual sebelum logout, _activeUserId sudah null duluan dan
    // clearLocation() diam-diam tidak pernah terpanggil (ditemukan lewat
    // uji langsung di HP: posisi lama masih muncul setelah login ulang).
    await _trackingService.stopTracking();
    await _repository.clearLocation(widget.user.uid);
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const FirebaseLoginPage()),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Live Tracking (Firebase)'),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isBusy ? null : _signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                border: Border.all(color: colors.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.iconSoftBlue,
                    child: Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.email ?? widget.user.uid,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'UID: ${widget.user.uid}',
                          style: AppTypography.small.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ================================================================
            // STATUS PELACAKAN + TOMBOL START/STOP
            // ================================================================
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                border: Border.all(color: colors.border.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isTracking
                            ? Icons.gps_fixed_rounded
                            : Icons.gps_off_rounded,
                        color: _isTracking
                            ? AppColors.success
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _isTracking ? 'Pelacakan aktif' : 'Pelacakan tidak aktif',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isBusy ? null : _toggleTracking,
                      icon: Icon(
                        _isTracking
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                      ),
                      label: Text(_isTracking ? 'Hentikan' : 'Mulai Lacak'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracking
                            ? AppColors.danger
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ================================================================
            // POSISI TERKINI (real-time dari Firestore)
            // ================================================================
            Text(
              'POSISI TERKINI (FIRESTORE)',
              style: AppTypography.sectionLabel.copyWith(
                fontSize: 12,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            StreamBuilder<LiveLocationPoint?>(
              stream: _repository.watchLocation(widget.user.uid),
              builder: (context, snapshot) {
                final point = snapshot.data;
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: point == null
                      ? Text(
                          'Belum ada posisi tersimpan. Tekan "Mulai Lacak" untuk mulai mengirim koordinat.',
                          style: AppTypography.small.copyWith(
                            color: colors.textSecondary,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(
                              label: 'Latitude',
                              value: point.latitude.toStringAsFixed(6),
                            ),
                            _InfoRow(
                              label: 'Longitude',
                              value: point.longitude.toStringAsFixed(6),
                            ),
                            _InfoRow(
                              label: 'Akurasi',
                              value: point.accuracy != null
                                  ? '±${point.accuracy!.toStringAsFixed(1)} m'
                                  : '-',
                            ),
                            _InfoRow(
                              label: 'Kecepatan',
                              value: point.speed != null
                                  ? '${point.speed!.toStringAsFixed(1)} m/s'
                                  : '-',
                            ),
                            _InfoRow(
                              label: 'Diperbarui',
                              value: point.updatedAt != null
                                  ? point.updatedAt!.toLocal().toString()
                                  : '-',
                            ),
                          ],
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.small.copyWith(color: colors.textSecondary),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
