import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/storage_breakdown_entity.dart';
import '../../domain/usecases/clear_app_cache.dart';
import '../../domain/usecases/get_storage_breakdown.dart';

/// DeviceStoragePage
/// ----------------------------------------------------------------------
/// Rincian penggunaan ruang penyimpanan lokal perangkat oleh Tulap.id
/// (Database, Foto Bukti, Cache) dan aksi pembersihan cache yang aman.
/// ----------------------------------------------------------------------
class DeviceStoragePage extends StatefulWidget {
  const DeviceStoragePage({super.key});

  @override
  State<DeviceStoragePage> createState() => _DeviceStoragePageState();
}

class _DeviceStoragePageState extends State<DeviceStoragePage> {
  StorageBreakdownEntity? _storage;
  bool _isLoading = true;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() => _isLoading = true);
    final getStorage = sl<GetStorageBreakdown>();
    final info = await getStorage();
    if (mounted) {
      setState(() {
        _storage = info;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmClearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        ),
        title: const Text('Bersihkan Cache?'),
        content: const Text(
          'File sementara akan dihapus untuk menghemat ruang. Seluruh foto bukti dan data kegiatan Anda TETAP AMAN dan tidak akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bersihkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isClearing = true);
    final clearCache = sl<ClearAppCache>();
    final result = await clearCache();

    if (!mounted) return;
    setState(() => _isClearing = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${failure.message}'),
            backgroundColor: AppColors.danger,
          ),
        );
      },
      (bytes) {
        final formatted = StorageBreakdownEntity.formatBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil membersihkan $formatted cache.'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadStorageInfo();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Penyimpanan Perangkat'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. TOTAL STORAGE HERO CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
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
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.storage_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Tulap.id Menggunakan',
                                style: AppTypography.small.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _storage?.formattedTotal ?? '0 MB',
                            style: AppTypography.pageTitle.copyWith(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Penyimpanan lokal dioptimalkan untuk akses offline di lapangan.',
                            style: AppTypography.small.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 2. BREAKDOWN RINCIAN
                    _buildSectionTitle('RINCIAN PENYIMPANAN LOKAL'),
                    Container(
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          _buildStorageItem(
                            icon: Icons.photo_library_outlined,
                            title: 'Foto & Bukti Lapangan',
                            subtitle: 'Foto terkompresi & watermark geotag',
                            sizeText: _storage?.formattedPhotos ?? '0 B',
                            color: AppColors.primary,
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildStorageItem(
                            icon: Icons.table_chart_outlined,
                            title: 'Database Lokal (SQLite)',
                            subtitle: 'Daftar tugas, kegiatan, timeline, & outbox',
                            sizeText: _storage?.formattedDatabase ?? '0 B',
                            color: AppColors.action,
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildStorageItem(
                            icon: Icons.cached_rounded,
                            title: 'Cache & File Sementara',
                            subtitle: 'Pratinjau render & cache gambar',
                            sizeText: _storage?.formattedCache ?? '0 B',
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 3. KEAMANAN DATA NOTE
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.iconSoftBlue,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Pembersihan cache hanya menghapus file sementara yang tidak esensial. Seluruh bukti foto, nota, dan rekaman kegiatan tetap aman di penyimpanan permanen.',
                              style: AppTypography.small.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 4. BERSIHKAN CACHE ACTION
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isClearing ? null : _confirmClearCache,
                        icon: _isClearing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_sweep_outlined, size: 20),
                        label: const Text('Bersihkan Cache Sekarang'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.sectionLabel.copyWith(
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadowSoft,
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
      border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
    );
  }

  Widget _buildStorageItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String sizeText,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.small.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            sizeText,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
