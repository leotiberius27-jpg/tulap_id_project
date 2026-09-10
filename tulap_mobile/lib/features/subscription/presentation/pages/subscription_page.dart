import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/entities/plan_code.dart';
import '../../domain/entities/plan_entity.dart';
import '../controllers/subscription_controller.dart';
import '../widgets/billing_cycle_selector.dart';
import '../widgets/plan_comparison_sheet.dart';
import '../widgets/plan_folder_carousel.dart';
import '../widgets/plan_page_indicator.dart';
import 'purchase_summary_page.dart';

/// SubscriptionPage ("Pilih Paket Tulap")
/// ----------------------------------------------------------------------
/// Redesign halaman pemilihan paket Tulap sebagai folder carousel
/// interaktif (dokumen redesign lengkap - lihat komentar per widget
/// turunan untuk pemetaan tiap bagian dokumen). Paket, harga, kuota, dan
/// status langganan SEMUA dibaca dari SubscriptionController - halaman
/// ini murni presentasi.
/// ----------------------------------------------------------------------
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SubscriptionController>(
      create: (_) => SubscriptionController(
        getPlans: sl(),
        getCurrentSubscription: sl(),
        getSubscriptionUsage: sl(),
        selectPlan: sl(),
      )..load(),
      child: const _SubscriptionView(),
    );
  }
}

class _SubscriptionView extends StatelessWidget {
  const _SubscriptionView();

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Pilih Paket Tulap'),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<SubscriptionController>(
          builder: (context, controller, _) {
            switch (controller.status) {
              case SubscriptionLoadStatus.loading:
                return const AppLoadingView(label: 'Memuat paket Tulap...');
              case SubscriptionLoadStatus.error:
                return AppErrorState(
                  message: controller.errorMessage ?? 'Terjadi kesalahan.',
                  onRetry: controller.load,
                );
              case SubscriptionLoadStatus.loaded:
                return _SubscriptionLoadedBody(controller: controller);
            }
          },
        ),
      ),
    );
  }
}

class _SubscriptionLoadedBody extends StatelessWidget {
  final SubscriptionController controller;

  const _SubscriptionLoadedBody({required this.controller});

  /// Paket GRATIS tetap lewat SubscriptionController (backend
  /// /subscriptions/select-free, Bagian 41 instruksi payment). Paket
  /// BERBAYAR SELALU lewat checkout QRIS/VA - TIDAK PERNAH diaktifkan
  /// langsung dari tombol paket (Bagian 63 - "Do Not: mengaktifkan
  /// paket dari frontend"). Halaman Plan Folder Carousel sendiri TIDAK
  /// disentuh (Bagian 39) - hanya CTA-nya diarahkan ke sini.
  Future<void> _handleCtaPressed(BuildContext context, PlanEntity plan) async {
    if (plan.code == PlanCode.gratis) {
      final messenger = ScaffoldMessenger.of(context);
      final success = await controller.confirmSelectPlan(plan);
      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${plan.displayName} berhasil diaktifkan.'
                : controller.selectPlanError ?? 'Gagal memperbarui paket.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PurchaseSummaryPage(plan: plan, billingCycle: controller.billingCycle),
      ),
    );
    // Setelah kembali dari alur checkout (berhasil ATAU dibatalkan),
    // muat ulang status langganan - jika pembayaran sukses, backend
    // sudah mengaktifkan paket & CTA/usage di sini akan ikut berubah.
    if (context.mounted) {
      await controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final folderHeight = (screenHeight * 0.5).clamp(400.0, 540.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                  ),
                  child: Text(
                    'Pilih paket berdasarkan seberapa sering Anda bertugas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13.5,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: BillingCycleSelector(
                    value: controller.billingCycle,
                    onChanged: controller.setBillingCycle,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PlanFolderCarousel(
                  plans: controller.plans,
                  selectedIndex: controller.selectedIndex,
                  billingCycle: controller.billingCycle,
                  viewModelFor: controller.viewModelFor,
                  onSettled: controller.setSelectedIndex,
                  onCtaPressed: (plan) => _handleCtaPressed(context, plan),
                  height: folderHeight,
                ),
                const SizedBox(height: AppSpacing.md),
                PlanPageIndicator(
                  count: controller.plans.length,
                  selectedIndex: controller.selectedIndex,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Geser folder ke kiri atau kanan',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => PlanComparisonSheet.show(
                    context,
                    plans: controller.plans,
                    billingCycle: controller.billingCycle,
                  ),
                  child: const Text('Lihat perbandingan lengkap paket'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
