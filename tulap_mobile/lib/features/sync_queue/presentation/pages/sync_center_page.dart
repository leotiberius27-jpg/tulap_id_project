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
      appBar: AppBar(title: const Text('Pusat Sinkronisasi')),
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
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: ElevatedButton(
                onPressed: controller.isRetryingAll ? null : controller.retryAll,
                child: controller.isRetryingAll
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kirim Semua Sekarang'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Belum ada data yang perlu disinkronkan.',
          style: AppTypography.bodySecondary,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAllSyncedState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 48),
            SizedBox(height: AppSpacing.md),
            Text('Semua data sudah terkirim', style: AppTypography.sectionTitle),
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
      child: Text(title, style: AppTypography.sectionTitle),
    );
  }
}
