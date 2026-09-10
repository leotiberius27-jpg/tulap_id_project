import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/plan_code.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_owner_type.dart';
import '../../domain/entities/subscription_status.dart';

/// SubscriptionLocalDataSource
/// ----------------------------------------------------------------------
/// Menyimpan langganan personal user di flutter_secure_storage - pola
/// yang sama seperti AuthLocalDataSource untuk sesi login. Belum ada
/// payment gateway sungguhan di project ini (lihat SelectPlan use case),
/// jadi ini adalah sumber kebenaran ENTITLEMENT saat ini sampai backend
/// billing tersedia; kontrak repository tidak perlu berubah saat itu
/// terjadi.
/// ----------------------------------------------------------------------
class SubscriptionLocalDataSource {
  static const String _subscriptionKey = 'subscription_state_v1';

  final FlutterSecureStorage _secureStorage;

  SubscriptionLocalDataSource({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<SubscriptionEntity?> getSubscription() async {
    final raw = await _secureStorage.read(key: _subscriptionKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SubscriptionEntity(
        id: map['id'] as String,
        ownerType: SubscriptionOwnerType.values.byName(
          map['ownerType'] as String,
        ),
        ownerId: map['ownerId'] as String,
        planCode: PlanCode.values.byName(map['planCode'] as String),
        billingCycle: BillingCycle.values.byName(map['billingCycle'] as String),
        status: SubscriptionStatus.values.byName(map['status'] as String),
        currentPeriodStart: DateTime.parse(map['currentPeriodStart'] as String),
        currentPeriodEnd: DateTime.parse(map['currentPeriodEnd'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSubscription(SubscriptionEntity subscription) async {
    await _secureStorage.write(
      key: _subscriptionKey,
      value: jsonEncode({
        'id': subscription.id,
        'ownerType': subscription.ownerType.name,
        'ownerId': subscription.ownerId,
        'planCode': subscription.planCode.name,
        'billingCycle': subscription.billingCycle.name,
        'status': subscription.status.name,
        'currentPeriodStart': subscription.currentPeriodStart.toIso8601String(),
        'currentPeriodEnd': subscription.currentPeriodEnd.toIso8601String(),
      }),
    );
  }
}
