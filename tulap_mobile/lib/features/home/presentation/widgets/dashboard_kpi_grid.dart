import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/domain/entities/dashboard_summary_entity.dart';

class DashboardKpiGrid extends StatelessWidget {
  final DashboardSummaryEntity summary;
  final VoidCallback? onActivityTap;
  final VoidCallback? onTravelTap;
  final VoidCallback? onEvidenceTap;
  final VoidCallback? onExpenseTap;

  const DashboardKpiGrid({
    super.key,
    required this.summary,
    this.onActivityTap,
    this.onTravelTap,
    this.onEvidenceTap,
    this.onExpenseTap,
  });

  String _formatExpenseCompact(double amount) {
    if (amount >= 1000000000) {
      return 'Rp${(amount / 1000000000).toStringAsFixed(2).replaceAll('.', ',')} M';
    }
    if (amount >= 1000000) {
      return 'Rp${(amount / 1000000).toStringAsFixed(2).replaceAll('.', ',')} jt';
    }
    if (amount >= 1000) {
      return 'Rp${(amount / 1000).toStringAsFixed(0)} rb';
    }
    return 'Rp${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 340;
          final cardWidth = (constraints.maxWidth - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // 1. Kegiatan
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  context,
                  title: 'Kegiatan',
                  value: summary.activityTotal.toString(),
                  subtitle: summary.activityTotal > 0
                      ? '${summary.activityCompleted} selesai (${summary.activityCompletionRate.toInt()}%)'
                      : '0 selesai',
                  icon: Icons.assignment_outlined,
                  iconColor: AppColors.primary,
                  isNarrow: isNarrow,
                  onTap: onActivityTap,
                ),
              ),

              // 2. Perjalanan Dinas
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  context,
                  title: 'Perjalanan',
                  value: summary.travelTotal.toString(),
                  subtitle: '${summary.travelDays} hari total',
                  icon: Icons.flight_takeoff_rounded,
                  iconColor: AppColors.primary,
                  isNarrow: isNarrow,
                  onTap: onTravelTap,
                ),
              ),

              // 3. Dokumentasi Bukti
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  context,
                  title: 'Dokumentasi',
                  value: summary.evidenceTotal.toString(),
                  subtitle: summary.videoCount > 0
                      ? '${summary.photoCount} foto • ${summary.videoCount} video'
                      : '${summary.photoCount} foto ber-GPS',
                  icon: Icons.camera_alt_outlined,
                  iconColor: AppColors.success,
                  isNarrow: isNarrow,
                  onTap: onEvidenceTap,
                ),
              ),

              // 4. Pengeluaran
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  context,
                  title: 'Pengeluaran',
                  value: _formatExpenseCompact(summary.expenseTotal),
                  subtitle: 'Terkonfirmasi',
                  icon: Icons.receipt_long_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  isNarrow: isNarrow,
                  onTap: onExpenseTap,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isNarrow,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isNarrow ? 12 : 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isNarrow ? 18 : 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
