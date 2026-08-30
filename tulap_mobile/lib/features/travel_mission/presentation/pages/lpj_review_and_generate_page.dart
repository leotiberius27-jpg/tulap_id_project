import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/usecases/get_travel_mission_detail.dart';
import '../controllers/travel_mission_detail_controller.dart';
import 'lpj_package_preview_page.dart';

class LpjReviewAndGeneratePage extends StatelessWidget {
  final TravelMissionDetailBundle bundle;

  const LpjReviewAndGeneratePage({super.key, required this.bundle});

  @override
  Widget build(BuildContext context) {
    try {
      Provider.of<TravelMissionDetailController>(context, listen: false);
      return _LpjReviewAndGeneratePageView(bundle: bundle);
    } catch (_) {
      return ChangeNotifierProvider<TravelMissionDetailController>(
        create: (_) => sl<TravelMissionDetailController>()..loadDetail(bundle.travel.id),
        child: _LpjReviewAndGeneratePageView(bundle: bundle),
      );
    }
  }
}

class _LpjReviewAndGeneratePageView extends StatefulWidget {
  final TravelMissionDetailBundle bundle;

  const _LpjReviewAndGeneratePageView({required this.bundle});

  @override
  State<_LpjReviewAndGeneratePageView> createState() => _LpjReviewAndGeneratePageViewState();
}

class _LpjReviewAndGeneratePageViewState extends State<_LpjReviewAndGeneratePageView> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TravelMissionDetailController>();
    final state = controller.state;
    final bundle = state.bundle ?? widget.bundle;
    final completeness = bundle.completeness;
    final travel = bundle.travel;
    final summary = bundle.expenseSummary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: const Text(
          'Pemeriksaan & Buat Paket LPJ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          icon: state.isGeneratingLpj
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf, color: AppColors.onPrimary),
          label: Text(
            state.isGeneratingLpj ? 'Menghasilkan Paket LPJ...' : 'Cetak & Terbitkan Paket LPJ',
            style: const TextStyle(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: completeness.isReadyForLpj ? AppColors.primary : AppColors.textMuted,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: (!completeness.isReadyForLpj || state.isGeneratingLpj)
              ? null
              : () async {
                  final nav = Navigator.of(context);
                  await controller.generateLpj();
                  if (!mounted) return;
                  if (controller.state.errorMessage == null) {
                    final updatedBundle = controller.state.bundle;
                    if (updatedBundle != null && updatedBundle.lpjPackages.isNotEmpty) {
                      nav.pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => LpjPackagePreviewPage(
                            package: updatedBundle.lpjPackages.first,
                          ),
                        ),
                      );
                    }
                  }
                },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      travel.displayId,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Skor Kelengkapan: ${completeness.percentage}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: completeness.percentage == 100
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  travel.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${travel.origin} → ${travel.destination} (${travel.formattedPeriod})',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Blockers alert if any
          if (completeness.blockers.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cancel, color: AppColors.danger, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Item Wajib Belum Lengkap',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...completeness.blockers.map((b) => Padding(
                        padding: const EdgeInsets.only(left: 24, bottom: 4),
                        child: Text('• $b', style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Checklist Section
          const Text(
            'Checklist Kelengkapan Dokumen & Data',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: completeness.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: item.isCompleted ? AppColors.success : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: item.isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                                  ),
                                ),
                                if (item.isMandatory) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.dangerSoft,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'WAJIB',
                                      style: TextStyle(fontSize: 9, color: AppColors.danger, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              item.description,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (item.statusDetail != null)
                        Text(
                          item.statusDetail!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.isCompleted ? AppColors.success : AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Financial Summary
          const Text(
            'Ringkasan Keuangan Yang Akan Dicantumkan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildRow('Pagu Anggaran Disetujui', _currencyFormat.format(summary.estimatedBudget)),
                const Divider(height: 14, color: AppColors.border),
                _buildRow('Total Realisasi Pengeluaran', _currencyFormat.format(summary.totalActualExpense)),
                const Divider(height: 14, color: AppColors.border),
                _buildRow(
                  'Selisih Efisiensi / Sisa',
                  _currencyFormat.format(summary.varianceAmount),
                  valueColor: summary.varianceAmount < 0 ? AppColors.danger : AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
