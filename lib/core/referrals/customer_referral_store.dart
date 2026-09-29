import 'package:flutter/foundation.dart';

enum CustomerReferralStatus {
  invited,
  registered,
  firstOrderCompleted,
  rewardAvailable,
}

extension CustomerReferralStatusLabel on CustomerReferralStatus {
  String get label {
    switch (this) {
      case CustomerReferralStatus.invited:
        return 'Invite sent';
      case CustomerReferralStatus.registered:
        return 'Registered';
      case CustomerReferralStatus.firstOrderCompleted:
        return 'First eligible order completed';
      case CustomerReferralStatus.rewardAvailable:
        return 'Reward available';
    }
  }

  String get shortLabel {
    switch (this) {
      case CustomerReferralStatus.invited:
        return 'INVITED';
      case CustomerReferralStatus.registered:
        return 'REGISTERED';
      case CustomerReferralStatus.firstOrderCompleted:
        return 'COMPLETED';
      case CustomerReferralStatus.rewardAvailable:
        return 'REWARDED';
    }
  }
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

  String get referralCode => 'GETIN-MOHAMMED';

  String get referralLink => 'https://getin.coffee/ref/$referralCode';

  String get shareMessage =>
      'Good coffee is better together. Join me on Getin Coffee with code '
      '$referralCode and complete your eligible first order to unlock the '
      'referral offer.\n$referralLink';

  List<CustomerReferralActivity> get history =>
      List<CustomerReferralActivity>.unmodifiable(_history);

  final List<CustomerReferralActivity> _history =
      const <CustomerReferralActivity>[
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

  int get invitedCount => _history.length;

  int get completedCount => _history.where((item) => item.completed).length;

  double get totalEarned => _history.fold<double>(
        0,
        (sum, item) => sum + item.rewardEarned,
      );
}
