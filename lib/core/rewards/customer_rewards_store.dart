import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RewardBenefitType {
  freeDrink,
  freeSizeUpgrade,
}

enum RewardRedemptionStatus {
  available,
  applied,
  used,
}

class RewardDefinition {
  final String id;
  final String title;
  final String description;
  final int starsRequired;
  final RewardBenefitType benefitType;
  final String usageText;
  final double maximumSaving;

  const RewardDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.starsRequired,
    required this.benefitType,
    required this.usageText,
    required this.maximumSaving,
  });
}

class RedeemedReward {
  final String id;
  final String definitionId;
  final String code;
  final DateTime redeemedAt;
  final RewardRedemptionStatus status;

  const RedeemedReward({
    required this.id,
    required this.definitionId,
    required this.code,
    required this.redeemedAt,
    required this.status,
  });

  RedeemedReward copyWith({
    RewardRedemptionStatus? status,
  }) {
    return RedeemedReward(
      id: id,
      definitionId: definitionId,
      code: code,
      redeemedAt: redeemedAt,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'definitionId': definitionId,
      'code': code,
      'redeemedAt': redeemedAt.toIso8601String(),
      'status': status.name,
    };
  }

  static RedeemedReward? fromJson(Map<String, Object?> json) {
    final id = json['id'] as String?;
    final definitionId = json['definitionId'] as String?;
    final code = json['code'] as String?;
    final redeemedAt = DateTime.tryParse(json['redeemedAt'] as String? ?? '');
    final statusName = json['status'] as String?;

    if (id == null ||
        definitionId == null ||
        code == null ||
        redeemedAt == null ||
        statusName == null) {
      return null;
    }

    final status = RewardRedemptionStatus.values.where(
      (value) => value.name == statusName,
    );

    if (status.isEmpty) {
      return null;
    }

    return RedeemedReward(
      id: id,
      definitionId: definitionId,
      code: code,
      redeemedAt: redeemedAt,
      status: status.first,
    );
  }
}

class RewardHistoryEntry {
  final String id;
  final String title;
  final int starsDelta;
  final DateTime occurredAt;
  final String? subtitle;

  const RewardHistoryEntry({
    required this.id,
    required this.title,
    required this.starsDelta,
    required this.occurredAt,
    this.subtitle,
  });

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'starsDelta': starsDelta,
      'occurredAt': occurredAt.toIso8601String(),
      'subtitle': subtitle,
    };
  }

  static RewardHistoryEntry? fromJson(Map<String, Object?> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String?;
    final starsDelta = json['starsDelta'] as int?;
    final occurredAt = DateTime.tryParse(json['occurredAt'] as String? ?? '');

    if (id == null ||
        title == null ||
        starsDelta == null ||
        occurredAt == null) {
      return null;
    }

    return RewardHistoryEntry(
      id: id,
      title: title,
      starsDelta: starsDelta,
      occurredAt: occurredAt,
      subtitle: json['subtitle'] as String?,
    );
  }
}

enum RewardRedeemResult {
  success,
  insufficientStars,
}

class CustomerRewardsStore extends ChangeNotifier {
  CustomerRewardsStore._();

  static final CustomerRewardsStore instance = CustomerRewardsStore._();

  static const String _starsKey = 'getin_demo_rewards_stars_v1';
  static const String _redeemedKey = 'getin_demo_redeemed_rewards_v1';
  static const String _historyKey = 'getin_demo_rewards_history_v1';

  static const List<RewardDefinition> catalog = [
    RewardDefinition(
      id: 'free-size-upgrade',
      title: 'Free Size Upgrade',
      description: 'Upgrade one eligible Getin drink to Large on us.',
      starsRequired: 80,
      benefitType: RewardBenefitType.freeSizeUpgrade,
      usageText:
          'Use on one eligible Large drink in Cart or Checkout. The demo applies up to EGP 10 for the size upgrade.',
      maximumSaving: 10,
    ),
    RewardDefinition(
      id: 'free-drink',
      title: 'Free Drink',
      description:
          'Enjoy one eligible handcrafted Getin drink with your Stars.',
      starsRequired: 150,
      benefitType: RewardBenefitType.freeDrink,
      usageText:
          'Use on one eligible drink in Cart or Checkout. The demo covers up to EGP 85; paid add-ons above the eligible value remain chargeable.',
      maximumSaving: 85,
    ),
  ];

  SharedPreferences? _preferences;
  int _stars = 120;
  List<RedeemedReward> _redeemedRewards = <RedeemedReward>[];
  List<RewardHistoryEntry> _history = <RewardHistoryEntry>[];

  int get stars => _stars;
  List<RedeemedReward> get redeemedRewards =>
      List.unmodifiable(_redeemedRewards);
  List<RewardHistoryEntry> get history => List.unmodifiable(_history);

  List<RedeemedReward> get activeRewards => _redeemedRewards
      .where(
        (reward) => reward.status != RewardRedemptionStatus.used,
      )
      .toList(growable: false);

  int get activeRewardCount => activeRewards.length;

  int get starsUntilNextReward {
    final remainingCosts = catalog
        .map((reward) => reward.starsRequired)
        .where((cost) => cost > _stars)
        .toList()
      ..sort();

    if (remainingCosts.isEmpty) {
      return 0;
    }

    return remainingCosts.first - _stars;
  }

  int get nextRewardTarget {
    final costs = catalog.map((reward) => reward.starsRequired).toList()
      ..sort();

    for (final cost in costs) {
      if (cost > _stars) {
        return cost;
      }
    }

    return costs.isEmpty ? 1 : costs.last;
  }

  static Future<void> initialize() async {
    final store = instance;
    store._preferences = await SharedPreferences.getInstance();
    store._load();
  }

  RewardDefinition definitionFor(String definitionId) {
    return catalog.firstWhere(
      (definition) => definition.id == definitionId,
      orElse: () => catalog.first,
    );
  }

  RedeemedReward? redeemedById(String id) {
    for (final reward in _redeemedRewards) {
      if (reward.id == id) {
        return reward;
      }
    }
    return null;
  }

  void addBonusStars({
    required int stars,
    required String title,
    String? subtitle,
  }) {
    if (stars <= 0) return;

    final now = DateTime.now();
    _stars += stars;
    _history.insert(
      0,
      RewardHistoryEntry(
        id: 'bonus-${now.microsecondsSinceEpoch}',
        title: title,
        starsDelta: stars,
        occurredAt: now,
        subtitle: subtitle ?? 'Getin Play bonus',
      ),
    );
    _changed();
  }

  void addOrderEarnings({
    required int stars,
    required String orderId,
    required bool memberMultiplierApplied,
  }) {
    if (stars <= 0) return;

    final now = DateTime.now();
    _stars += stars;
    _history.insert(
      0,
      RewardHistoryEntry(
        id: 'earn-$orderId-${now.millisecondsSinceEpoch}',
        title: 'Order #$orderId',
        starsDelta: stars,
        occurredAt: now,
        subtitle: memberMultiplierApplied
            ? '1.5× Membership Stars applied'
            : 'Stars earned from an eligible order',
      ),
    );
    _changed();
  }

  RedeemedReward grantFreeDrinkReward({
    required String source,
  }) {
    final now = DateTime.now();
    final suffix = now.microsecondsSinceEpoch.toString();
    final tail = suffix.substring(suffix.length - 6);
    final fromPlay = source.startsWith('getin-play');
    final redemption = RedeemedReward(
      id: 'free-drink-$source-$suffix',
      definitionId: 'free-drink',
      code: fromPlay ? 'GETIN-PLAY-$tail' : 'GETIN-STAMP-$tail',
      redeemedAt: now,
      status: RewardRedemptionStatus.available,
    );

    _redeemedRewards.insert(0, redemption);
    _history.insert(
      0,
      RewardHistoryEntry(
        id: '${fromPlay ? 'play' : 'stamp'}-reward-$suffix',
        title: fromPlay
            ? 'Getin Play Free Drink won'
            : '7-stamp Free Drink unlocked',
        starsDelta: 0,
        occurredAt: now,
        subtitle: redemption.code,
      ),
    );
    _changed();
    return redemption;
  }

  RewardRedeemResult redeem(RewardDefinition definition) {
    if (_stars < definition.starsRequired) {
      return RewardRedeemResult.insufficientStars;
    }

    _stars -= definition.starsRequired;

    final now = DateTime.now();
    final suffix = now.millisecondsSinceEpoch.toString();
    final redemption = RedeemedReward(
      id: '${definition.id}-$suffix',
      definitionId: definition.id,
      code: _buildCode(definition, suffix),
      redeemedAt: now,
      status: RewardRedemptionStatus.available,
    );

    _redeemedRewards.insert(0, redemption);
    _history.insert(
      0,
      RewardHistoryEntry(
        id: 'redeem-$suffix',
        title: '${definition.title} redeemed',
        starsDelta: -definition.starsRequired,
        occurredAt: now,
        subtitle: redemption.code,
      ),
    );

    _changed();
    return RewardRedeemResult.success;
  }

  void markApplied(String redemptionId) {
    _updateStatus(
      redemptionId,
      RewardRedemptionStatus.applied,
    );
  }

  void markAvailable(String redemptionId) {
    final reward = redeemedById(redemptionId);
    if (reward == null || reward.status == RewardRedemptionStatus.used) {
      return;
    }

    _updateStatus(
      redemptionId,
      RewardRedemptionStatus.available,
    );
  }

  void markUsed(String redemptionId) {
    _updateStatus(
      redemptionId,
      RewardRedemptionStatus.used,
    );
  }

  void resetToDemoDefaults({
    bool persist = false,
  }) {
    _setDemoDefaults();
    notifyListeners();
    if (persist) {
      unawaited(_persist());
    }
  }

  void _load() {
    final preferences = _preferences;
    if (preferences == null || !preferences.containsKey(_starsKey)) {
      _setDemoDefaults();
      unawaited(_persist());
      notifyListeners();
      return;
    }

    _stars = preferences.getInt(_starsKey) ?? 120;
    _redeemedRewards = _decodeRedeemed(
      preferences.getString(_redeemedKey),
    ).map((reward) {
      // Normalize any persisted APPLIED marker first. CartController restores
      // the cart after Rewards/Vouchers initialize and reapplies the benefit
      // only when the restored cart is still eligible.
      return reward.status == RewardRedemptionStatus.applied
          ? reward.copyWith(status: RewardRedemptionStatus.available)
          : reward;
    }).toList();
    _history = _decodeHistory(
      preferences.getString(_historyKey),
    );

    if (_history.isEmpty) {
      _history = _defaultHistory();
    }

    notifyListeners();
  }

  void _setDemoDefaults() {
    final now = DateTime.now();
    _stars = 120;
    _redeemedRewards = [
      RedeemedReward(
        id: 'demo-free-drink-001',
        definitionId: 'free-drink',
        code: 'GETIN-FREE-001',
        redeemedAt: now.subtract(const Duration(days: 3)),
        status: RewardRedemptionStatus.available,
      ),
    ];
    _history = _defaultHistory(now: now);
  }

  List<RewardHistoryEntry> _defaultHistory({DateTime? now}) {
    final reference = now ?? DateTime.now();
    return [
      RewardHistoryEntry(
        id: 'history-order-10583',
        title: 'Order #10583',
        starsDelta: 18,
        occurredAt: reference.subtract(const Duration(days: 1)),
        subtitle: 'Stars earned from an eligible order',
      ),
      RewardHistoryEntry(
        id: 'history-double-stars',
        title: 'Bonus Stars promotion',
        starsDelta: 10,
        occurredAt: reference.subtract(const Duration(days: 2)),
        subtitle: 'Promotion bonus',
      ),
      RewardHistoryEntry(
        id: 'history-free-drink',
        title: 'Free Drink redeemed',
        starsDelta: -150,
        occurredAt: reference.subtract(const Duration(days: 3)),
        subtitle: 'GETIN-FREE-001',
      ),
    ];
  }

  String _buildCode(RewardDefinition definition, String suffix) {
    final tail =
        suffix.length <= 6 ? suffix : suffix.substring(suffix.length - 6);
    return definition.benefitType == RewardBenefitType.freeDrink
        ? 'GETIN-DRINK-$tail'
        : 'GETIN-UPGRADE-$tail';
  }

  void _updateStatus(
    String redemptionId,
    RewardRedemptionStatus status,
  ) {
    final index = _redeemedRewards.indexWhere(
      (reward) => reward.id == redemptionId,
    );

    if (index == -1 || _redeemedRewards[index].status == status) {
      return;
    }

    _redeemedRewards[index] = _redeemedRewards[index].copyWith(
      status: status,
    );
    _changed();
  }

  void _changed() {
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    await preferences.setInt(_starsKey, _stars);
    await preferences.setString(
      _redeemedKey,
      jsonEncode(
        _redeemedRewards.map((reward) => reward.toJson()).toList(),
      ),
    );
    await preferences.setString(
      _historyKey,
      jsonEncode(
        _history.map((entry) => entry.toJson()).toList(),
      ),
    );
  }

  List<RedeemedReward> _decodeRedeemed(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <RedeemedReward>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <RedeemedReward>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (entry) => RedeemedReward.fromJson(
              Map<String, Object?>.from(entry),
            ),
          )
          .whereType<RedeemedReward>()
          .toList();
    } catch (_) {
      return <RedeemedReward>[];
    }
  }

  List<RewardHistoryEntry> _decodeHistory(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <RewardHistoryEntry>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <RewardHistoryEntry>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (entry) => RewardHistoryEntry.fromJson(
              Map<String, Object?>.from(entry),
            ),
          )
          .whereType<RewardHistoryEntry>()
          .toList();
    } catch (_) {
      return <RewardHistoryEntry>[];
    }
  }
}
