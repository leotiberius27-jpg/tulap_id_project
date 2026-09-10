import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/plan_entity.dart';

/// PlanComparisonSheet
/// ----------------------------------------------------------------------
/// "Lihat perbandingan lengkap paket" (Bagian 39 dokumen redesign) -
/// mengikuti pola bottom sheet existing Tulap.id (isScrollControlled,
/// drag handle, radius atas AppRadius.bottomSheetTop). Folder di
/// carousel fokus pada keputusan cepat; sheet ini untuk detail.
/// ----------------------------------------------------------------------
class PlanComparisonSheet extends StatelessWidget {
  final List<PlanEntity> plans;
  final BillingCycle billingCycle;

  const PlanComparisonSheet({
    super.key,
    required this.plans,
    required this.billingCycle,
  });

  static Future<void> show(
    BuildContext context, {
    required List<PlanEntity> plans,
    required BillingCycle billingCycle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          PlanComparisonSheet(plans: plans, billingCycle: billingCycle),
    );
  }

  static const List<_ComparisonRow> _rows = [
    _ComparisonRow('Kegiatan / bulan', _ComparisonKind.activityLimit),
    _ComparisonRow('Foto geotag & watermark', _ComparisonKind.always),
    _ComparisonRow('Scan nota otomatis', _ComparisonKind.fromBasic),
    _ComparisonRow('Offline & sinkronisasi', _ComparisonKind.fromBasic),
    _ComparisonRow('Tula AI', _ComparisonKind.fromPro),
    _ComparisonRow('Pengeluaran & arsip', _ComparisonKind.fromBasic),
    _ComparisonRow('LPJ PDF & Word', _ComparisonKind.fromPro),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.bottomSheetTop),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Perbandingan Paket',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Table(
                    columnWidths: const {0: FlexColumnWidth(1.3)},
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: colors.border,
                        width: 1,
                      ),
                    ),
                    children: [
                      _headerRow(colors),
                      for (final row in _rows) _dataRow(colors, row),
                      _priceRow(colors),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  TableRow _headerRow(TulapThemeColors colors) {
    return TableRow(
      children: [
        const SizedBox(height: 40),
        for (final plan in plans)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              plan.tabLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: colors.primary,
              ),
            ),
          ),
      ],
    );
  }

  TableRow _priceRow(TulapThemeColors colors) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Harga',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        for (final plan in plans)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                plan.isFree
                    ? 'Gratis'
                    : '${AppDateFormatter.formatRupiah(plan.priceFor(billingCycle))}${billingCycle.priceSuffix}',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  TableRow _dataRow(TulapThemeColors colors, _ComparisonRow row) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            row.label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.5,
              color: colors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
        for (final plan in plans)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Center(child: _cellFor(colors, row, plan)),
          ),
      ],
    );
  }

  Widget _cellFor(
    TulapThemeColors colors,
    _ComparisonRow row,
    PlanEntity plan,
  ) {
    if (row.kind == _ComparisonKind.activityLimit) {
      return Text(
        '${plan.activityLimit}',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      );
    }

    final included = switch (row.kind) {
      _ComparisonKind.always => true,
      _ComparisonKind.fromBasic => plan.code.index >= 1,
      _ComparisonKind.fromPro => plan.code.index >= 2,
      _ComparisonKind.activityLimit => false,
    };

    return Icon(
      included ? Icons.check_circle_rounded : Icons.remove_rounded,
      size: 18,
      color: included ? colors.success : colors.border,
      semanticLabel: included ? 'Tersedia' : 'Tidak tersedia',
    );
  }
}

enum _ComparisonKind { activityLimit, always, fromBasic, fromPro }

class _ComparisonRow {
  final String label;
  final _ComparisonKind kind;

  const _ComparisonRow(this.label, this.kind);
}
