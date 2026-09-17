import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/domain/entities/dashboard_period.dart';

class DashboardPeriodSelector extends StatelessWidget {
  final DashboardPeriod selectedPeriod;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  const DashboardPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Flexible(
            child: Text(
              'Ringkasan & Analisis',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showPeriodPicker(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selectedPeriod.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPeriodPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Periode Analitik',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  context,
                  title: 'Hari Ini',
                  period: DashboardPeriod.today(),
                ),
                _buildOptionTile(
                  context,
                  title: '7 Hari Terakhir',
                  period: DashboardPeriod.sevenDays(),
                ),
                _buildOptionTile(
                  context,
                  title: '30 Hari Terakhir',
                  period: DashboardPeriod.thirtyDays(),
                ),
                _buildOptionTile(
                  context,
                  title: 'Bulan Ini',
                  period: DashboardPeriod.thisMonth(),
                ),
                _buildOptionTile(
                  context,
                  title: 'Tahun Ini',
                  period: DashboardPeriod.thisYear(),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.date_range, color: AppColors.primary),
                  title: const Text(
                    'Pilih Rentang Tanggal...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDateRange: DateTimeRange(
                        start: selectedPeriod.startDate,
                        end: selectedPeriod.endDate,
                      ),
                      locale: const Locale('id', 'ID'),
                    );
                    if (range != null) {
                      final fmt = DateFormat('d MMM', 'id_ID');
                      final label = '${fmt.format(range.start)} - ${fmt.format(range.end)}';
                      onPeriodChanged(
                        DashboardPeriod.custom(
                          start: range.start,
                          end: range.end,
                          label: label,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required String title,
    required DashboardPeriod period,
  }) {
    final isSelected = selectedPeriod.type == period.type &&
        selectedPeriod.label == period.label;

    return ListTile(
      dense: true,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          : null,
      onTap: () {
        Navigator.of(context).pop();
        onPeriodChanged(period);
      },
    );
  }
}
