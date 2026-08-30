import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/domain/entities/travel_destination_stat.dart';

class TravelLpjIntelligenceCard extends StatelessWidget {
  final int travelTotal;
  final int travelDays;
  final int lpjComplete;
  final int lpjIncomplete;
  final List<TravelDestinationStat> destinations;
  final VoidCallback? onTravelTap;
  final VoidCallback? onIncompleteLpjTap;

  const TravelLpjIntelligenceCard({
    super.key,
    required this.travelTotal,
    required this.travelDays,
    required this.lpjComplete,
    required this.lpjIncomplete,
    required this.destinations,
    this.onTravelTap,
    this.onIncompleteLpjTap,
  });

  @override
  Widget build(BuildContext context) {
    if (travelTotal == 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lpjCompletionRate = travelTotal > 0
        ? ((lpjComplete / travelTotal) * 100).toInt()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : AppColors.primary.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.flight_takeoff_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Perjalanan Dinas & SPPD',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onTravelTap,
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Metrics row: Travel Days & LPJ Status
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hari Dinas',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$travelDays Hari',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: lpjIncomplete > 0 ? onIncompleteLpjTap : onTravelTap,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: lpjIncomplete > 0
                            ? (isDark
                                ? const Color(0xFF332314)
                                : const Color(0xFFFEF3C7))
                            : (isDark
                                ? const Color(0xFF142E1F)
                                : const Color(0xFFECFDF5)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Kelengkapan LPJ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: lpjIncomplete > 0
                                      ? AppColors.warning
                                      : AppColors.success,
                                ),
                              ),
                              if (lpjIncomplete > 0)
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 12,
                                  color: AppColors.warning,
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lpjIncomplete > 0
                                ? '$lpjIncomplete Perlu Dilengkapi'
                                : '$lpjCompletionRate% Lengkap',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: lpjIncomplete > 0
                                  ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309))
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (destinations.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Destinasi Utama:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: destinations.map((d) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${d.destination} (${d.count})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
