import 'package:flutter/foundation.dart';

import '../data/customer_repository.dart';
import '../engagement/customer_engagement_api_repository.dart';

enum CustomerReferralStatus {
  invited,
  registered,
  firstOrderCompleted,
  rewardAvailable
}

extension CustomerReferralStatusLabel on CustomerReferralStatus {
  String get label => switch (this) {
        CustomerReferralStatus.invited => 'Invite sent',
        CustomerReferralStatus.registered => 'Registered',
        CustomerReferralStatus.firstOrderCompleted =>
          'First eligible order completed',
        CustomerReferralStatus.rewardAvailable => 'Reward available',
      };
  String get shortLabel => switch (this) {
        CustomerReferralStatus.invited => 'INVITED',
        CustomerReferralStatus.registered => 'REGISTERED',
        CustomerReferralStatus.firstOrderCompleted => 'COMPLETED',
        CustomerReferralStatus.rewardAvailable => 'REWARDED',
      };
}

@immutable
class CustomerReferralActivity {
  final String id;
  final String friendName;
  final CustomerReferralStatus status;
  final String dateLabel;
  final double rewardEarned;
  const CustomerReferralActivity({
    required this.id,
    required this.friendName,
    required this.status,
    required this.dateLabel,
    this.rewardEarned = 0,
  });
  bool get completed =>
      status == CustomerReferralStatus.firstOrderCompleted ||
      status == CustomerReferralStatus.rewardAvailable;
}

class CustomerReferralStore extends ChangeNotifier {
  CustomerReferralStore._();
  static final CustomerReferralStore instance = CustomerReferralStore._();

  CustomerEngagementApiRepository? _repository;
  String _referralCode = 'GETIN-MOHAMMED';
  List<CustomerReferralActivity> _history = _demoHistory;
  int _referredCount = 0;
  int _rewardedCount = 0;
  String? _campaignName;
  String? _referrerRewardType;
  int? _referrerRewardPoints;
  bool _hasAppliedReferral = false;

  bool get usesApi => _repository?.usesApi ?? false;
  String get referralCode => _referralCode;
  String get referralLink => 'https://getin.coffee/ref/$referralCode';
  String get shareMessage =>
      'Good coffee is better together. Join me on GETIN Coffee with code $referralCode.\n$referralLink';
  List<CustomerReferralActivity> get history => List.unmodifiable(_history);
  int get invitedCount => usesApi ? _referredCount : _history.length;
  int get referredCount => usesApi ? _referredCount : _history.length;
  int get rewardedCount => usesApi
      ? _rewardedCount
      : _history.where((item) => item.status == CustomerReferralStatus.rewardAvailable).length;
  int get completedCount => usesApi
      ? _rewardedCount
      : _history.where((item) => item.completed).length;
  String? get campaignName => _campaignName;
  bool get hasAppliedReferral => _hasAppliedReferral;
  String get programHeadline {
    if (!usesApi) return 'Give EGP 50. Get EGP 50.';
    if (_referrerRewardType == 'points' && _referrerRewardPoints != null) {
      return 'Invite friends. Earn $_referrerRewardPoints Stars.';
    }
    if ((_referrerRewardType ?? '').contains('voucher')) {
      return 'Invite friends. Unlock GETIN rewards.';
    }
    return _campaignName ?? 'Refer friends with GETIN';
  }
  double get totalEarned =>
      _history.fold<double>(0, (sum, item) => sum + item.rewardEarned);

  static Future<void> initialize([CustomerRepositoryContext? context]) async {
    if (context != null) {
      instance._repository = CustomerEngagementApiRepository(context);
    }
    if (instance.usesApi) {
      await instance.refresh();
    }
  }

  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null || !repository.usesApi) {
      return;
    }
    final summary = await repository.referralProgram();
    _referralCode = summary['referral_code']?.toString() ?? _referralCode;
    _referredCount = (summary['referred_count'] as num?)?.toInt() ?? 0;
    _rewardedCount = (summary['rewarded_count'] as num?)?.toInt() ?? 0;
    _hasAppliedReferral = summary['applied_referral'] is Map;
    final campaign = summary['campaign'];
    if (campaign is Map) {
      _campaignName = campaign['name']?.toString();
      final reward = campaign['referrer_reward'];
      if (reward is Map) {
        _referrerRewardType = reward['type']?.toString();
        _referrerRewardPoints = (reward['points'] as num?)?.toInt();
      }
    } else {
      _campaignName = null;
      _referrerRewardType = null;
      _referrerRewardPoints = null;
    }
    final items = await repository.referrals();
    _history = items.map(_fromApi).toList(growable: false);
    notifyListeners();
  }

  Future<void> applyCode(String code) async {
    final repository = _repository;
    if (repository == null || !repository.usesApi) {
      return;
    }
    await repository.applyReferralCode(code);
    await refresh();
  }

  CustomerReferralActivity _fromApi(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString().toLowerCase() ?? '';
    final status = rawStatus.contains('reward')
        ? CustomerReferralStatus.rewardAvailable
        : rawStatus.contains('qualif') || rawStatus.contains('complete')
            ? CustomerReferralStatus.firstOrderCompleted
            : rawStatus.contains('register') || rawStatus.contains('appl')
                ? CustomerReferralStatus.registered
                : CustomerReferralStatus.invited;
    final referee = json['referee'];
    final name = referee is Map ? referee['name']?.toString() : null;
    final date =
        json['rewarded_at'] ?? json['qualified_at'] ?? json['applied_at'];
    final parsed = DateTime.tryParse(date?.toString() ?? '');
    final label = parsed == null ? '' : '${parsed.day}/${parsed.month}';
    return CustomerReferralActivity(
      id: json['id']?.toString() ?? '',
      friendName: name ?? 'Friend',
      status: status,
      dateLabel: label,
    );
  }

  static const List<CustomerReferralActivity> _demoHistory =
      <CustomerReferralActivity>[
    CustomerReferralActivity(
      id: 'ref-demo-1',
      friendName: 'Sara H.',
      status: CustomerReferralStatus.rewardAvailable,
      dateLabel: '18 Sep',
      rewardEarned: 50,
    ),
    CustomerReferralActivity(
      id: 'ref-demo-2',
      friendName: 'Omar A.',
      status: CustomerReferralStatus.registered,
      dateLabel: '22 Sep',
    ),
    CustomerReferralActivity(
      id: 'ref-demo-3',
      friendName: 'Karim M.',
      status: CustomerReferralStatus.invited,
      dateLabel: '23 Sep',
    ),
    CustomerReferralActivity(
      id: 'ref-demo-4',
      friendName: 'Laila Y.',
      status: CustomerReferralStatus.rewardAvailable,
      dateLabel: '12 Sep',
      rewardEarned: 50,
    ),
  ];
}
