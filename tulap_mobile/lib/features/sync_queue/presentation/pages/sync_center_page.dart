import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/entities/sync_record_entity.dart';
import '../controllers/sync_center_controller.dart';
import '../widgets/sync_status_row.dart';

/// SyncCenterPage
/// ----------------------------------------------------------------------
/// Layar Sync Center sesuai Bagian 10 spesifikasi. Diakses dari menu
/// Akun (Data & Sinkronisasi -> Status Sinkronisasi) maupun dari banner
/// status sinkronisasi di Beranda ("X data menunggu internet" -> CTA
/// "Lihat Data").
/// ----------------------------------------------------------------------
class SyncCenterPage extends StatelessWidget {
  const SyncCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      Provider.of<SyncCenterController>(context, listen: false);
      return const _SyncCenterPageView();
    } catch (_) {
      return ChangeNotifierProvider<SyncCenterController>(
        create: (_) => SyncCenterController(
          repository: sl(),
          backgroundSyncService: sl(),
        ),
        child: const _SyncCenterPageView(),
      );
    }
  }
}

class _SyncCenterPageView extends StatelessWidget {
  const _SyncCenterPageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pusat Sinkronisasi'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<SyncCenterController>(
            builder: (context, controller, _) {
              return IconButton(
                icon: controller.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                tooltip: 'Muat Ulang',
                onPressed: controller.isLoading ? null : controller.loadRecords,
              );
            },
          ),
        ],
      ),
      body: Consumer<SyncCenterController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.records.isEmpty) {
            return const AppLoadingView(label: 'Memuat status antrian sinkronisasi...');
          }

          final records = controller.records;
          final failedRecords = controller.failedRecords;
          final pendingRecords = controller.pendingRecords;
          final syncedRecords = records.where((r) => r.status == SyncStatus.synced).toList();

          return RefreshIndicator(
            onRefresh: controller.loadRecords,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // ============================================================
                // 1. STATUS SUMMARY HEADER CARD
                // ============================================================
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: controller.allSynced
                                  ? AppColors.successSoft
                                  : (failedRecords.isNotEmpty
                                      ? AppColors.dangerSoft
                                      : AppColors.warningSoft),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              controller.allSynced
                                  ? Icons.cloud_done_rounded
                                  : (failedRecords.isNotEmpty
                                      ? Icons.cloud_off_rounded
                                      : Icons.cloud_sync_rounded),
                              color: controller.allSynced
                                  ? AppColors.success
                                  : (failedRecords.isNotEmpty
                                      ? AppColors.danger
                                      : AppColors.warning),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.allSynced
                                      ? 'Semua Data Terkirim'
                                      : (failedRecords.isNotEmpty
                                          ? '${failedRecords.length} Data Perlu Diperbaiki'
                                          : '${pendingRecords.length} Data Menunggu Dikirim'),
                                  style: AppTypography.sectionTitle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  controller.isBackgroundSyncing
                                      ? 'Sedang mengirim data ke server...'
                                      : (controller.allSynced
                                          ? 'Pekerjaan Anda tersimpan aman di server.'
                                          : 'Data tersimpan di perangkat & siap disinkronkan.'),
                                  style: AppTypography.small.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _StatItem(
                            label: 'Terkirim',
                            value: '${syncedRecords.length}',
                            color: AppColors.success,
                          ),
                          _StatItem(
                            label: 'Menunggu',
                            value: '${pendingRecords.length}',
                            color: AppColors.warning,
                          ),
                          _StatItem(
                            label: 'Gagal',
                            value: '${failedRecords.length}',
                            color: AppColors.danger,
                          ),
                          _StatItem(
                            label: 'Total Antrian',
                            value: '${records.length}',
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ============================================================
                // 2. EMPTY STATE JIKA TIDAK ADA DATA SAMA SEKALI
                // ============================================================
                if (records.isEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  const AppEmptyState(
                    icon: Icons.cloud_done_outlined,
                    title: 'Belum ada antrian sinkronisasi',
                    message: 'Semua foto bukti, nota, dan checklist langsung disinkronkan secara otomatis saat terhubung internet.',
                  ),
                ],

                // ============================================================
                // 3. SECTION GAGAL / PERLU DIPERBAIKI
                // ============================================================
                if (failedRecords.isNotEmpty) ...[
                  _SectionHeader(title: 'Perlu Diperbaiki (${failedRecords.length})'),
                  ...failedRecords.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: SyncStatusRow(
                        record: r,
                        onRetry: () => controller.retryOne(r.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ============================================================
                // 4. SECTION DALAM PROSES / MENUNGGU INTERNET
                // ============================================================
                if (pendingRecords.isNotEmpty) ...[
                  _SectionHeader(title: 'Menunggu Pengiriman (${pendingRecords.length})'),
                  ...pendingRecords.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: SyncStatusRow(record: r),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ============================================================
                // 5. SECTION RIWAYAT BERHASIL TERKIRIM
                // ============================================================
                if (syncedRecords.isNotEmpty) ...[
                  _SectionHeader(title: 'Terkirim ke Server (${syncedRecords.length})'),
                  ...syncedRecords.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: SyncStatusRow(record: r),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<SyncCenterController>(
        builder: (context, controller, _) {
          final hasPendingOrFailed =
              controller.pendingRecords.isNotEmpty || controller.failedRecords.isNotEmpty;

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: ElevatedButton(
                  onPressed: controller.isRetryingAll || controller.isBackgroundSyncing
                      ? null
                      : () => controller.retryAll(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPendingOrFailed ? AppColors.action : AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: controller.isRetryingAll || controller.isBackgroundSyncing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              controller.pendingRecords.isNotEmpty
                                  ? 'Mengirim ${controller.pendingRecords.length} data...'
                                  : 'Menghubungi server...',
                              style: AppTypography.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sync_rounded, size: 20, color: Colors.white),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              hasPendingOrFailed ? 'Kirim Semua Sekarang' : 'Sinkronkan Ulang Sekarang',
                              style: AppTypography.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.sectionTitle.copyWith(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.small.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: Text(
        title,
        style: AppTypography.sectionLabel.copyWith(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

