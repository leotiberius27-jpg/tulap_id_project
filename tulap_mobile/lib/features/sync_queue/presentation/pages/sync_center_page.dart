import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
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
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.records.isEmpty) {
            return _buildEmptyState();
          }

          if (controller.allSynced) {
            return _buildAllSyncedState();
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
                  onPressed: controller.isRetryingAll
                      ? null
                      : controller.retryAll,
                  child: controller.isRetryingAll
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_done_outlined,
                color: AppColors.textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Belum ada data yang perlu disinkronkan.',
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllSyncedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Semua data sudah terkirim',
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: 4),
            const Text(
              'Data aman dan tersimpan di server.',
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
