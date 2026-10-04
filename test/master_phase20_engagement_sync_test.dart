import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 210 refreshes engagement state after authentication', () {
    final sync = File(
      'lib/core/auth/customer_account_sync.dart',
    ).readAsStringSync();
    final main = File('lib/core/bootstrap/customer_app_bootstrap.dart')
        .readAsStringSync();

    expect(sync, contains('CustomerMembershipStore.instance.refresh'));
    expect(sync, contains('CustomerRewardsStore.instance.refresh'));
    expect(sync, contains('CustomerStampCardStore.instance.refresh'));
    expect(sync, contains('CustomerPlayStore.instance.refresh'));
    expect(sync, contains('CustomerReferralStore.instance.refresh'));
    expect(
      main.indexOf('CustomerReferralStore.initialize(context)'),
      lessThan(main.indexOf('CustomerAccountSync.refreshAfterAuthentication')),
    );
  });

  test('Task 210 isolates live tier UI from demo paid membership', () {
    final membership = File(
      'lib/features/membership/membership_screen.dart',
    ).readAsStringSync();
    final rewardsCard = File(
      'lib/features/home/widgets/rewards_progress_card.dart',
    ).readAsStringSync();

    expect(membership, contains('MembershipJoinedPreview('));
    expect(membership, isNot(contains('_LiveMembershipScreen')));
    final loyaltyTiers = File(
      'lib/features/rewards/loyalty_tiers_screen.dart',
    ).readAsStringSync();
    expect(loyaltyTiers, contains('store.loyaltyEarningMultiplierLabel'));
    expect(loyaltyTiers, contains('store.pointsToNext'));
    expect(loyaltyTiers, contains('...store.tiers.map'));
    expect(rewardsCard, contains('earningMultiplierLabel'));
  });
}
