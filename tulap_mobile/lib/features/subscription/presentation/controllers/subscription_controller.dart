import 'package:flutter/foundation.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/plan_code.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_usage_entity.dart';
import '../../domain/usecases/get_current_subscription.dart';
import '../../domain/usecases/get_plans.dart';
import '../../domain/usecases/get_subscription_usage.dart';
import '../../domain/usecases/select_plan.dart';
import '../widgets/plan_folder_carousel.dart';

enum SubscriptionLoadStatus { loading, loaded, error }

/// SubscriptionController
/// ----------------------------------------------------------------------
/// Satu-satunya pemilik state Halaman Paket Tulap: daftar paket,
/// langganan aktif user, pemakaian kuota, siklus penagihan, dan paket
/// yang sedang tersorot di carousel. Semua widget presentasi HANYA
/// membaca state ini - tidak ada logic bisnis tersebar di widget
/// (Bagian 36 dokumen redesign).
/// ----------------------------------------------------------------------
class SubscriptionController extends ChangeNotifier {
  final GetPlans _getPlans;
  final GetCurrentSubscription _getCurrentSubscription;
  final GetSubscriptionUsage _getSubscriptionUsage;
  final SelectPlan _selectPlan;

  SubscriptionController({
    required GetPlans getPlans,
    required GetCurrentSubscription getCurrentSubscription,
    required GetSubscriptionUsage getSubscriptionUsage,
    required SelectPlan selectPlan,
  }) : _getPlans = getPlans,
       _getCurrentSubscription = getCurrentSubscription,
       _getSubscriptionUsage = getSubscriptionUsage,
       _selectPlan = selectPlan;

  SubscriptionLoadStatus status = SubscriptionLoadStatus.loading;
  String? errorMessage;

  List<PlanEntity> plans = const [];
  SubscriptionEntity? currentSubscription;
  SubscriptionUsageEntity? currentPlanUsage;

  int selectedIndex = 0;
  BillingCycle billingCycle = BillingCycle.monthly;

  PlanCode? _pendingPlanCode;
  String? _selectPlanError;

  PlanEntity get selectedPlan => plans[selectedIndex];

  PlanCode? get currentPlanCode =>
      currentSubscription?.planCode ?? PlanCode.gratis;

  bool get isSelectingPlan => _pendingPlanCode != null;

  String? get selectPlanError => _selectPlanError;

  Future<void> load() async {
    status = SubscriptionLoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    final plansResult = await _getPlans();
    final subscriptionResult = await _getCurrentSubscription();

    final plansFailure = plansResult.isLeft();
    final subscriptionFailure = subscriptionResult.isLeft();

    if (plansFailure || subscriptionFailure) {
      status = SubscriptionLoadStatus.error;
      errorMessage = 'Tidak dapat memuat paket Tulap. Periksa koneksi Anda.';
      notifyListeners();
      return;
    }

    plans = plansResult.fold((_) => const [], (value) => value);
    currentSubscription = subscriptionResult.fold(
      (_) => null,
      (value) => value,
    );
    billingCycle = currentSubscription?.billingCycle ?? BillingCycle.monthly;

    // Belum pernah memilih paket -> default PRO (Bagian 2 dokumen
    // redesign). Sudah punya langganan sungguhan -> tampilkan paket
    // miliknya, meski itu GRATIS.
    final effectivePlanCode = currentSubscription?.planCode ?? PlanCode.pro;
    final defaultIndex = plans.indexWhere((p) => p.code == effectivePlanCode);
    final proIndex = plans.indexWhere((p) => p.code == PlanCode.pro);
    selectedIndex = defaultIndex >= 0
        ? defaultIndex
        : (proIndex >= 0 ? proIndex : 0);

    await _loadUsage();

    status = SubscriptionLoadStatus.loaded;
    notifyListeners();
  }

  Future<void> _loadUsage() async {
    final usageResult = await _getSubscriptionUsage(
      currentPlanCode ?? PlanCode.gratis,
    );
    currentPlanUsage = usageResult.fold((_) => null, (value) => value);
  }

  void setSelectedIndex(int index) {
    if (index == selectedIndex) return;
    selectedIndex = index;
    notifyListeners();
  }

  void setBillingCycle(BillingCycle cycle) {
    if (cycle == billingCycle) return;
    billingCycle = cycle; // Carousel/selectedIndex SENGAJA tidak disentuh.
    notifyListeners();
  }

  /// Ringkasan siap-tampil satu folder - dipakai carousel & tempat lain
  /// yang butuh status paket tanpa mengulang logic bisnis.
  PlanCardViewModel viewModelFor(PlanEntity plan) {
    final isCurrentPlan = plan.code == (currentPlanCode ?? PlanCode.gratis);
    final hasExplicitSubscription = currentSubscription != null;
    final currentTierIndex = PlanCode.values.indexOf(
      currentPlanCode ?? PlanCode.gratis,
    );
    final thisTierIndex = PlanCode.values.indexOf(plan.code);

    String ctaLabel;
    if (isCurrentPlan) {
      ctaLabel = 'Paket Aktif';
    } else if (hasExplicitSubscription && thisTierIndex > currentTierIndex) {
      ctaLabel = 'Upgrade ke ${plan.displayName}';
    } else if (hasExplicitSubscription && thisTierIndex < currentTierIndex) {
      ctaLabel = 'Ubah ke ${plan.displayName}';
    } else {
      ctaLabel = plan.ctaLabel;
    }

    return PlanCardViewModel(
      plan: plan,
      isCurrentPlan: isCurrentPlan,
      usage: isCurrentPlan ? currentPlanUsage : null,
      ctaLabel: ctaLabel,
      isCtaEnabled: !isCurrentPlan,
      isCtaLoading: _pendingPlanCode == plan.code,
    );
  }

  /// HANYA valid untuk paket GRATIS (Bagian 41 instruksi payment) -
  /// pemanggil (SubscriptionPage) sudah memastikan ini sebelum
  /// memanggil, lihat SelectPlan use case.
  Future<bool> confirmSelectPlan(PlanEntity plan) async {
    if (_pendingPlanCode != null) return false;
    _pendingPlanCode = plan.code;
    _selectPlanError = null;
    notifyListeners();

    final result = await _selectPlan();

    var success = false;
    result.fold((failure) => _selectPlanError = failure.message, (
      subscription,
    ) {
      currentSubscription = subscription;
      success = true;
    });

    if (success) {
      await _loadUsage();
    }

    _pendingPlanCode = null;
    notifyListeners();
    return success;
  }
}
