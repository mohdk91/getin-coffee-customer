import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/customer_repository.dart';
import '../engagement/customer_engagement_api_repository.dart';

class StampEarnResult {
  final int stampsAdded;
  final int cardsCompleted;
  final int currentStamps;
  const StampEarnResult({
    required this.stampsAdded,
    required this.cardsCompleted,
    required this.currentStamps,
  });
}


@immutable
class CustomerStampCardSnapshot {
  final int campaignId;
  final String campaignName;
  final String description;
  final int requiredStamps;
  final int stampsPerOrder;
  final String rewardType;
  final int? rewardPoints;
  final int stamps;
  final int remaining;
  final int completionCount;
  final String status;

  const CustomerStampCardSnapshot({
    required this.campaignId,
    required this.campaignName,
    required this.description,
    required this.requiredStamps,
    required this.stampsPerOrder,
    required this.rewardType,
    required this.rewardPoints,
    required this.stamps,
    required this.remaining,
    required this.completionCount,
    required this.status,
  });

  factory CustomerStampCardSnapshot.fromApi(Map<String, dynamic> json) {
    final campaign = json['campaign'] is Map
        ? Map<String, dynamic>.from(json['campaign'] as Map)
        : const <String, dynamic>{};
    final card = json['card'] is Map
        ? Map<String, dynamic>.from(json['card'] as Map)
        : const <String, dynamic>{};
    final reward = campaign['reward'] is Map
        ? Map<String, dynamic>.from(campaign['reward'] as Map)
        : const <String, dynamic>{};
    final required = (campaign['required_stamps'] as num?)?.toInt() ?? 1;
    final stamps = (card['stamps'] as num?)?.toInt() ?? 0;
    return CustomerStampCardSnapshot(
      campaignId: (campaign['id'] as num?)?.toInt() ?? 0,
      campaignName: campaign['name']?.toString() ?? 'GETIN Stamp Card',
      description: campaign['description']?.toString() ?? '',
      requiredStamps: required <= 0 ? 1 : required,
      stampsPerOrder: (campaign['stamps_per_order'] as num?)?.toInt() ?? 1,
      rewardType: reward['type']?.toString() ?? '',
      rewardPoints: (reward['points'] as num?)?.toInt(),
      stamps: stamps,
      remaining: (card['remaining'] as num?)?.toInt() ??
          ((required - stamps).clamp(0, required)).toInt(),
      completionCount: (card['completion_count'] as num?)?.toInt() ?? 0,
      status: card['status']?.toString() ?? 'active',
    );
  }

  String get rewardLabel {
    if (rewardType == 'points' && rewardPoints != null) {
      return '$rewardPoints Stars';
    }
    if (rewardType.contains('voucher')) return 'voucher reward';
    return rewardType.isEmpty ? 'GETIN reward' : rewardType.replaceAll('_', ' ');
  }
}

class CustomerStampCardStore extends ChangeNotifier {
  CustomerStampCardStore._();
  static final CustomerStampCardStore instance = CustomerStampCardStore._();

  static const int stampsPerFreeDrink = 7;
  static const String _currentKey = 'getin_demo_stamp_current_v1';
  static const String _completedKey = 'getin_demo_stamp_completed_v1';
  static const String _totalKey = 'getin_demo_stamp_total_v1';

  SharedPreferences? _preferences;
  CustomerEngagementApiRepository? _repository;
  int _requiredStamps = stampsPerFreeDrink;
  int _currentStamps = 4;
  int _completedCards = 0;
  int _totalStamps = 4;
  List<CustomerStampCardSnapshot> _cards = const <CustomerStampCardSnapshot>[];

  bool get usesApi => _repository?.usesApi ?? false;
  int get requiredStamps => _requiredStamps;
  int get currentStamps => _currentStamps;
  int get completedCards => _completedCards;
  int get totalStamps => _totalStamps;
  List<CustomerStampCardSnapshot> get cards => List.unmodifiable(_cards);
  CustomerStampCardSnapshot? get activeCard => _cards.isEmpty ? null : _cards.first;
  String get campaignName => activeCard?.campaignName ?? '7 Cups, 1 On Us';
  String get campaignDescription => activeCard?.description.isNotEmpty == true
      ? activeCard!.description
      : 'Each eligible drink earns a stamp toward your next reward.';
  String get rewardLabel => activeCard?.rewardLabel ?? 'free drink reward';
  int get remaining =>
      (_requiredStamps - _currentStamps).clamp(0, _requiredStamps).toInt();
  double get progress =>
      _requiredStamps <= 0 ? 0 : _currentStamps / _requiredStamps;

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
    store._currentStamps =
        store._preferences?.getInt(_currentKey)?.clamp(0, 6).toInt() ?? 4;
    store._completedCards = store._preferences?.getInt(_completedKey) ?? 0;
    store._totalStamps = store._preferences?.getInt(_totalKey) ?? 4;
  }

  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null || !repository.usesApi) {
      return;
    }
    final items = await repository.stampCards();
    _cards = items
        .map(CustomerStampCardSnapshot.fromApi)
        .toList(growable: false);
    if (_cards.isEmpty) {
      _currentStamps = 0;
      _completedCards = 0;
      _totalStamps = 0;
      notifyListeners();
      return;
    }
    final first = _cards.first;
    _requiredStamps = first.requiredStamps;
    _currentStamps = first.stamps;
    _completedCards = first.completionCount;
    _totalStamps = _completedCards * _requiredStamps + _currentStamps;
    notifyListeners();
  }

  StampEarnResult addEligibleDrinks(int quantity) {
    if (usesApi || quantity <= 0) {
      return StampEarnResult(
          stampsAdded: 0, cardsCompleted: 0, currentStamps: _currentStamps);
    }
    final combined = _currentStamps + quantity;
    final completedNow = combined ~/ _requiredStamps;
    _currentStamps = combined % _requiredStamps;
    _completedCards += completedNow;
    _totalStamps += quantity;
    notifyListeners();
    unawaited(_persist());
    return StampEarnResult(
        stampsAdded: quantity,
        cardsCompleted: completedNow,
        currentStamps: _currentStamps);
  }

  @visibleForTesting
  void resetToDemoDefaults({bool persist = false}) {
    _requiredStamps = stampsPerFreeDrink;
    _currentStamps = 4;
    _completedCards = 0;
    _totalStamps = 4;
    notifyListeners();
    if (persist) {
      unawaited(_persist());
    }
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    await preferences.setInt(_currentKey, _currentStamps);
    await preferences.setInt(_completedKey, _completedCards);
    await preferences.setInt(_totalKey, _totalStamps);
  }
}
