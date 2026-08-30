import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/camera_preferences_entity.dart';
import '../../domain/entities/watermark_template_entity.dart';
import '../controllers/geotag_camera_controller.dart';
import '../widgets/template_selector_sheet.dart';

/// AdvancedCameraSettingsPage
/// ----------------------------------------------------------------------
/// Halaman Pengaturan Kamera Lengkap Tulap.id (Phase 4):
/// - Menghubungkan semua konfigurasi kamera, video, timer, rasio, grid, & mirror
/// - Terintegrasi satu pintu dengan Template & Watermark System (Phase 3)
/// - Menjaga imutabilitas bukti asli (Original Media) & integritas SHA-256
/// - Mendukung Reset Pengaturan Kamera dengan dialog konfirmasi aman
/// ----------------------------------------------------------------------
class AdvancedCameraSettingsPage extends StatelessWidget {
  final GeotagCameraController controller;

  const AdvancedCameraSettingsPage({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final prefs = state.cameraPreferences;
        final template = TemplateCatalog.getById(state.stampConfig.templateId);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A1120) : AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Pengaturan Kamera',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            centerTitle: true,
            backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // 1. SEKSI KAMERA & FOTO
                _buildSectionHeader('KAMERA & FOTO'),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    _buildSelectionTile(
                      icon: Icons.aspect_ratio_rounded,
                      title: 'Rasio Aspek Default',
                      subtitle: prefs.aspectRatio.description,
                      value: prefs.aspectRatio.label,
                      onTap: () => _showAspectRatioDialog(context),
                      isDark: isDark,
                    ),
                    const Divider(height: 1, indent: 52),
                    _buildSelectionTile(
                      icon: Icons.high_quality_rounded,
                      title: 'Kualitas Foto',
                      subtitle: prefs.photoQuality.description,
                      value: prefs.photoQuality.label,
                      onTap: () => _showPhotoQualityDialog(context),
                      isDark: isDark,
                    ),
                    const Divider(height: 1, indent: 52),
                    _buildSwitchTile(
                      icon: Icons.grid_on_rounded,
                      title: 'Kisi Komposisi (Grid 3x3)',
                      subtitle: 'Membantu keseimbangan komposisi foto lapangan',
                      value: prefs.gridEnabled,
                      onChanged: (_) => controller.toggleGrid(),
                      isDark: isDark,
                    ),
                    const Divider(height: 1, indent: 52),
                    _buildSwitchTile(
                      icon: Icons.flip_camera_android_rounded,
                      title: 'Cermin Kamera Depan (Mirror)',
                      subtitle: 'Simpan foto selfie sesuai pratinjau layar',
                      value: prefs.mirrorFrontCamera,
                      onChanged: (_) => controller.toggleMirrorFrontCamera(),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. SEKSI PEREKAMAN VIDEO
                _buildSectionHeader('PEREKAMAN VIDEO'),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.mic_rounded,
                      title: 'Rekam dengan Suara',
                      subtitle: 'Merekam audio mikrofon selama video berlangsung',
                      value: prefs.videoAudioEnabled,
                      onChanged: (_) => controller.toggleVideoAudio(),
                      isDark: isDark,
                    ),
                    const Divider(height: 1, indent: 52),
                    _buildSelectionTile(
                      icon: Icons.videocam_rounded,
                      title: 'Resolusi Video',
                      subtitle: prefs.videoQuality.description,
                      value: prefs.videoQuality.label,
                      onTap: () => _showVideoQualityDialog(context),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. SEKSI PENGAMBILAN & TOMBOL
                _buildSectionHeader('PENGAMBILAN BUKTI'),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    _buildSelectionTile(
                      icon: Icons.timer_rounded,
                      title: 'Timer Shutter Default',
                      subtitle: prefs.timerSeconds > 0
                          ? 'Hitung mundur ${prefs.timerSeconds} detik sebelum ambil foto'
                          : 'Langsung ambil foto tanpa jeda',
                      value: prefs.timerSeconds > 0
                          ? '${prefs.timerSeconds} Detik'
                          : 'Nonaktif',
                      onTap: () => _showTimerDialog(context),
                      isDark: isDark,
                    ),
                    const Divider(height: 1, indent: 52),
                    _buildSwitchTile(
                      icon: Icons.volume_down_rounded,
                      title: 'Tombol Volume untuk Shutter',
                      subtitle: 'Gunakan tombol volume fisik untuk mengambil foto',
                      value: prefs.volumeButtonShutter,
                      onChanged: (val) => controller.setVolumeButtonShutter(val),
                      isDark: isDark,
                    ),
                    const Divider(height: 1, indent: 52),
                    _buildLockedTile(
                      icon: Icons.verified_user_rounded,
                      title: 'Simpan Media Asli (Raw Evidence)',
                      subtitle: 'Wajib aktif untuk audit forensik dan verifikasi SHA-256',
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. SEKSI TAMPILAN KAMERA
                _buildSectionHeader('TAMPILAN KAMERA & SENSOR'),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.center_focus_strong_rounded,
                      title: 'Panduan Fokus & Exposure',
                      subtitle: 'Tampilkan cincin animasi saat mengetuk titik fokus',
                      value: prefs.focusGuideEnabled,
                      onChanged: (_) => controller.toggleFocusGuide(),
                      isDark: isDark,
                    ),
                    const Divider(height: 1, indent: 52),
                    _buildSwitchTile(
                      icon: Icons.screen_rotation_alt_rounded,
                      title: 'Indikator Level Horizon (Waterpass)',
                      subtitle: 'Membantu menjaga kamera tetap tegak lurus dan sejajar',
                      value: prefs.levelEnabled,
                      onChanged: (_) => controller.toggleLevelSensor(),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. SEKSI DOKUMENTASI & TEMPLATE
                _buildSectionHeader('DOKUMENTASI STAMP TULAP.ID'),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    _buildSelectionTile(
                      icon: Icons.auto_awesome_motion_rounded,
                      title: 'Template Stamp Aktif',
                      subtitle: template.description,
                      value: template.name,
                      onTap: () {
                        TemplateSelectorSheet.show(
                          context,
                          controller: controller,
                        );
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 6. TOMBOL RESET PENGATURAN KAMERA
                Material(
                  color: isDark ? const Color(0xFF0F172A) : AppColors.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: InkWell(
                    onTap: () => _showResetConfirmationDialog(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.restore_rounded,
                              color: Colors.red,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reset Pengaturan Kamera',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Kembalikan semua preferensi kamera ke bawaan standar',
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: Color(0xFF38BDF8),
        ),
      ),
    );
  }

  Widget _buildCardContainer({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Material(
      color: isDark ? const Color(0xFF0F172A) : AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0x1F006EE6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF006EE6), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF006EE6),
            onChanged: (val) {
              HapticFeedback.selectionClick();
              onChanged(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x1F006EE6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF006EE6), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006EE6),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'TERKUNCI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAspectRatioDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih Rasio Aspek Default'),
        children: CameraAspectRatio.values.map((ratio) {
          return SimpleDialogOption(
            onPressed: () {
              controller.setAspectRatio(ratio);
              Navigator.of(ctx).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${ratio.label} - ${ratio.description}'),
                if (controller.state.cameraPreferences.aspectRatio == ratio)
                  const Icon(Icons.check_rounded, color: Color(0xFF006EE6)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showPhotoQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih Kualitas Foto'),
        children: PhotoQualityPreference.values.map((quality) {
          return SimpleDialogOption(
            onPressed: () {
              controller.setPhotoQuality(quality);
              Navigator.of(ctx).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${quality.label} - ${quality.description}'),
                if (controller.state.cameraPreferences.photoQuality == quality)
                  const Icon(Icons.check_rounded, color: Color(0xFF006EE6)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showVideoQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih Kualitas Video'),
        children: VideoQualityPreference.values.map((quality) {
          return SimpleDialogOption(
            onPressed: () {
              controller.setVideoQuality(quality);
              Navigator.of(ctx).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${quality.label} - ${quality.description}'),
                if (controller.state.cameraPreferences.videoQuality == quality)
                  const Icon(Icons.check_rounded, color: Color(0xFF006EE6)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih Timer Shutter'),
        children: [0, 3, 5, 10].map((sec) {
          return SimpleDialogOption(
            onPressed: () {
              controller.setTimerSeconds(sec);
              Navigator.of(ctx).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sec == 0 ? 'Nonaktif (Tanpa Timer)' : '$sec Detik'),
                if (controller.state.cameraPreferences.timerSeconds == sec)
                  const Icon(Icons.check_rounded, color: Color(0xFF006EE6)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Pengaturan Kamera?'),
        content: const Text(
          'Semua preferensi rasio, timer, grid, dan kualitas akan dikembalikan ke bawaan Tulap.id.\n\nDokumentasi foto dan video yang sudah diambil tidak akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.resetCameraPreferences();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengaturan kamera berhasil direset ke bawaan.'),
                  backgroundColor: Color(0xFF006EE6),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
