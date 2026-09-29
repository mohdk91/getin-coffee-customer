import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _active = false;
  String _billingCycle = 'monthly';

  bool get isActive => _active || _previewMember;
  String get billingCycle => _billingCycle;

  static Future<void> initialize() async {
    final store = instance;
    store._preferences = await SharedPreferences.getInstance();
    store._active = store._preferences?.getBool(_activeKey) ?? false;
    store._billingCycle = store._preferences?.getString(_cycleKey) ?? 'monthly';
  }

  void activate({required String billingCycle}) {
    _active = true;
    _billingCycle = billingCycle;
    notifyListeners();
    unawaited(_persist());
  }

  void deactivateForTesting() {
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
