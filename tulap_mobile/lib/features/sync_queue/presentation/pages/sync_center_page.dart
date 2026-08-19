import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../controllers/sync_center_controller.dart';
import '../widgets/sync_status_row.dart';

/// SyncCenterPage
/// ----------------------------------------------------------------------
/// Layar Sync Center sesuai Bagian 10 spesifikasi. Diakses dari banner
/// status sinkronisasi di Beranda ("3 data menunggu internet" -> CTA
/// "Lihat Data").
/// ----------------------------------------------------------------------
class SyncCenterPage extends StatelessWidget {
  const SyncCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pusat Sinkronisasi'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<SyncCenterController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const AppLoadingView(label: 'Memuat data sinkronisasi...');
          }

          if (controller.records.isEmpty) {
            return const AppEmptyState(
              icon: Icons.cloud_done_outlined,
              title: 'Belum ada data yang perlu disinkronkan.',
            );
          }

          if (controller.allSynced) {
            return const AppEmptyState(
              icon: Icons.check_circle_outline,
              title: 'Semua data sudah terkirim',
              message: 'Data aman dan tersimpan di server.',
              iconColor: AppColors.success,
              iconBackground: AppColors.successSoft,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadRecords,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                if (controller.failedRecords.isNotEmpty) ...[
                  _SectionHeader(title: 'Perlu Diperbaiki'),
                  ...controller.failedRecords.map(
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
                if (controller.pendingRecords.isNotEmpty) ...[
                  _SectionHeader(title: 'Dalam Proses'),
                  ...controller.pendingRecords.map(
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
          if (controller.records.isEmpty || controller.allSynced) {
            return const SizedBox.shrink();
          }
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
                  onPressed:
                      controller.isRetryingAll || controller.isBackgroundSyncing
                      ? null
                      : controller.retryAll,
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
                              'Mengirim ${controller.pendingRecords.length} data...',
                            ),
                          ],
                        )
                      : const Text('Kirim Semua Sekarang'),
                ),
              ),
            ),
          );
        },
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.sectionLabel.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
