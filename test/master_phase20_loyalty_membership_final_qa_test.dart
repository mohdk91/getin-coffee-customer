import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 211 keeps Phase 20 engagement state server authoritative', () {
    final membership = File(
      'lib/core/membership/customer_membership_store.dart',
    ).readAsStringSync();
    final rewards = File(
      'lib/core/rewards/customer_rewards_store.dart',
    ).readAsStringSync();
    final stamps = File(
      'lib/core/rewards/customer_stamp_card_store.dart',
    ).readAsStringSync();
    final referrals = File(
      'lib/core/referrals/customer_referral_store.dart',
    ).readAsStringSync();
    final play = File(
      'lib/core/rewards/customer_play_store.dart',
    ).readAsStringSync();
    final playScreen = File(
      'lib/features/play/getin_play_screen.dart',
    ).readAsStringSync();
    final membershipScreen = File(
      'lib/features/membership/membership_screen.dart',
    ).readAsStringSync();
    final sync = File(
      'lib/core/auth/customer_account_sync.dart',
    ).readAsStringSync();

    expect(membership, contains("progress['percent_to_next']"));
    expect(membership, contains('pointsMultiplier'));
    expect(membership, contains('repository.membershipTiers()'));

    expect(rewards, contains('await _repository!.redeemReward(rewardId)'));
    expect(rewards, contains('await refresh();'));
    expect(stamps, contains('CustomerStampCardSnapshot.fromApi'));

    expect(referrals, contains("summary['referred_count']"));
    expect(referrals, contains("summary['rewarded_count']"));
    expect(referrals, contains("campaign['referrer_reward']"));

    expect(play, contains('final authoritative = _fromApi(attempt'));
    expect(play, contains('await refresh();'));
    expect(playScreen,
        contains('prize selection and rewards are decided by GETIN'));
    expect(
        playScreen, contains('await CustomerRewardsStore.instance.refresh();'));
    expect(
        playScreen, contains('await CustomerVoucherStore.instance.refresh();'));

    expect(membershipScreen, contains('MembershipJoinedPreview('));
    expect(membershipScreen, isNot(contains('_LiveMembershipScreen')));
    final loyaltyTiers = File(
      'lib/features/rewards/loyalty_tiers_screen.dart',
    ).readAsStringSync();
    expect(loyaltyTiers, contains('store.loyaltyEarningMultiplierLabel'));
    expect(loyaltyTiers, contains('...store.tiers.map'));
    expect(membershipScreen, contains('store.activate('));

    expect(sync, contains('CustomerMembershipStore.instance.refresh'));
    expect(sync, contains('CustomerReferralStore.instance.refresh'));
  });
}
