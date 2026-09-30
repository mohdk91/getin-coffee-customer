import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/customer_repository.dart';
import '../engagement/customer_engagement_api_repository.dart';

class CustomerMembershipStore extends ChangeNotifier {
  CustomerMembershipStore._();

  static final CustomerMembershipStore instance = CustomerMembershipStore._();

  static const String _activeKey = 'getin_demo_membership_active_v1';
  static const String _cycleKey = 'getin_demo_membership_cycle_v1';
  static const bool _previewMember = bool.fromEnvironment(
    'GETIN_PREVIEW_MEMBER',
    defaultValue: false,
  );

  SharedPreferences? _preferences;
  CustomerEngagementApiRepository? _repository;
  bool _active = false;
  String _billingCycle = 'monthly';
  String? _tierName;
  double _progress = 0;

  bool get usesApi => _repository?.usesApi ?? false;
  bool get isActive => _active || _previewMember;
  String get billingCycle => _billingCycle;
  String? get tierName => _tierName;
  double get progress => _progress;

  static Future<void> initialize([CustomerRepositoryContext? context]) async {
    final store = instance;
    if (context != null) {
      store._repository = CustomerEngagementApiRepository(context);
    }
    if (store.usesApi) {
      await store.refresh();
      return;
    }
    store._preferences = await SharedPreferences.getInstance();
    store._active = store._preferences?.getBool(_activeKey) ?? false;
    store._billingCycle = store._preferences?.getString(_cycleKey) ?? 'monthly';
  }

  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null || !repository.usesApi) return;
    final data = await repository.membership();
    final current = data['current_tier'];
    _active = current is Map;
    _tierName = current is Map ? current['name']?.toString() : null;
    final progress = data['progress'];
    if (progress is num) {
      _progress = progress.toDouble();
    } else if (progress is Map) {
      final raw = progress['percent'] ?? progress['progress_percent'];
      _progress = (raw as num?)?.toDouble() ?? 0;
    }
    notifyListeners();
  }

  void activate({required String billingCycle}) {
    if (usesApi) return;
    _active = true;
    _billingCycle = billingCycle;
    notifyListeners();
    unawaited(_persist());
  }

  void deactivateForTesting() {
    if (usesApi) return;
    _active = false;
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) return;
    await preferences.setBool(_activeKey, _active);
    await preferences.setString(_cycleKey, _billingCycle);
  }
}
