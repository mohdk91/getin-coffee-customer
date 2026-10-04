import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/customer_auth_store.dart';
import '../data/customer_repository.dart';
import '../engagement/customer_engagement_api_repository.dart';

@immutable
class CustomerMembershipTier {
  final int id;
  final String code;
  final String name;
  final int minimumLifetimePoints;
  final double pointsMultiplier;
  final Map<String, dynamic> benefits;

  const CustomerMembershipTier({
    required this.id,
    required this.code,
    required this.name,
    required this.minimumLifetimePoints,
    required this.pointsMultiplier,
    required this.benefits,
  });

  factory CustomerMembershipTier.fromApi(Map<String, dynamic> json) {
    return CustomerMembershipTier(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'GETIN',
      minimumLifetimePoints:
          (json['minimum_lifetime_points'] as num?)?.toInt() ?? 0,
      pointsMultiplier:
          double.tryParse(json['points_multiplier']?.toString() ?? '') ?? 1,
      benefits: json['benefits'] is Map
          ? Map<String, dynamic>.from(json['benefits'] as Map)
          : const <String, dynamic>{},
    );
  }

  bool get hasBonusMultiplier => pointsMultiplier > 1.0001;
  String get multiplierLabel => '${pointsMultiplier.toStringAsFixed(
        pointsMultiplier.truncateToDouble() == pointsMultiplier ? 0 : 2,
      )}×';
}

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
  CustomerMembershipTier? _currentTier;
  CustomerMembershipTier? _nextTier;
  List<CustomerMembershipTier> _tiers = const <CustomerMembershipTier>[];
  int _lifetimePoints = 0;
  int _pointsToNext = 0;
  double _progress = 0;

  bool get usesApi =>
      (_repository?.usesApi ?? false) &&
      CustomerAuthStore.instance.isAuthenticated;
  bool get isActive => _active || _previewMember;
  String get billingCycle => _billingCycle;
  String? get tierName => _currentTier?.name;
  String? get nextTierName => _nextTier?.name;
  CustomerMembershipTier? get currentTier => _currentTier;
  CustomerMembershipTier? get nextTier => _nextTier;
  List<CustomerMembershipTier> get tiers => List.unmodifiable(_tiers);
  int get lifetimePoints => _lifetimePoints;
  int get pointsToNext => _pointsToNext;
  double get progress => _progress;
  double get earningMultiplier => isActive ? 2 : 1;
  double get loyaltyEarningMultiplier =>
      usesApi ? (_currentTier?.pointsMultiplier ?? 1) : 1;
  bool get hasBonusMultiplier => earningMultiplier > 1.0001;
  String get earningMultiplierLabel => '${earningMultiplier.toStringAsFixed(
        earningMultiplier.truncateToDouble() == earningMultiplier ? 0 : 2,
      )}×';
  String get loyaltyEarningMultiplierLabel =>
      '${loyaltyEarningMultiplier.toStringAsFixed(
        loyaltyEarningMultiplier.truncateToDouble() == loyaltyEarningMultiplier
            ? 0
            : 2,
      )}×';

  static Future<void> initialize([CustomerRepositoryContext? context]) async {
    final store = instance;
    if (context != null) {
      store._repository = CustomerEngagementApiRepository(context);
    }
    store._preferences = await SharedPreferences.getInstance();
    CustomerAuthStore.instance.removeListener(store._handleAuthChanged);
    CustomerAuthStore.instance.addListener(store._handleAuthChanged);
    store._loadGuestMembership();
    if (store.usesApi) {
      await store.refresh();
      return;
    }
    store._clearLoyaltyState();
  }

  void _handleAuthChanged() {
    _loadGuestMembership();
    if (usesApi) {
      unawaited(refresh());
      return;
    }
    _clearLoyaltyState();
  }

  void _loadGuestMembership() {
    _active = _preferences?.getBool(_activeKey) ?? false;
    _billingCycle = _preferences?.getString(_cycleKey) ?? 'monthly';
    notifyListeners();
  }

  void _clearLoyaltyState() {
    _currentTier = null;
    _nextTier = null;
    _tiers = const <CustomerMembershipTier>[];
    _lifetimePoints = 0;
    _pointsToNext = 0;
    _progress = 0;
    notifyListeners();
  }

  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null || !usesApi) return;

    final data = await repository.membership();
    final current = data['current_tier'];
    final next = data['next_tier'];
    final tierItems = await repository.membershipTiers();

    _currentTier = current is Map
        ? CustomerMembershipTier.fromApi(Map<String, dynamic>.from(current))
        : null;
    _nextTier = next is Map
        ? CustomerMembershipTier.fromApi(Map<String, dynamic>.from(next))
        : null;
    _tiers =
        tierItems.map(CustomerMembershipTier.fromApi).toList(growable: false);

    final progress = data['progress'];
    if (progress is Map) {
      _lifetimePoints = (progress['lifetime_points'] as num?)?.toInt() ?? 0;
      _pointsToNext = (progress['points_to_next'] as num?)?.toInt() ?? 0;
      final rawPercent =
          progress['percent_to_next'] ?? progress['progress_percent'];
      _progress = (((rawPercent as num?)?.toDouble() ?? 0) / 100)
          .clamp(0.0, 1.0)
          .toDouble();
    } else if (progress is num) {
      _progress = (progress.toDouble() / 100).clamp(0.0, 1.0).toDouble();
    } else {
      _lifetimePoints = 0;
      _pointsToNext = 0;
      _progress = 0;
    }

    notifyListeners();
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
