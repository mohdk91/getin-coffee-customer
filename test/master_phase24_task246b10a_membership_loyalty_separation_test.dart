import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-10A restores paid Membership as its own experience', () {
    final screen = File(
      'lib/features/membership/membership_screen.dart',
    ).readAsStringSync();
    final joined = File(
      'lib/features/membership/membership_joined_preview.dart',
    ).readAsStringSync();

    expect(screen, contains("'Getin Membership'"));
    expect(screen, contains("title: '2× Stars'"));
    expect(screen, contains('MembershipJoinedPreview('));
    expect(screen, isNot(contains('_LiveMembershipScreen')));
    expect(screen, isNot(contains("'YOUR TIER'")));

    expect(joined, contains("'GETIN Member'"));
    expect(joined, contains("'2× Stars · member prices · monthly perks'"));
    expect(joined, contains("'Membership active'"));
    expect(joined, isNot(contains("'Green Member'")));
    expect(joined, isNot(contains("'Your tier journey'")));
  });

  test('Task 246B-10A keeps loyalty tiers available under Rewards', () {
    final rewards = File(
      'lib/features/rewards/rewards_screen.dart',
    ).readAsStringSync();
    final tiers = File(
      'lib/features/rewards/loyalty_tiers_screen.dart',
    ).readAsStringSync();

    expect(rewards, contains('_LoyaltyTierSummaryCard('));
    expect(rewards, contains('LoyaltyTiersScreen()'));
    expect(rewards, contains("active ? 'GETIN Member' : 'GETIN Membership'"));
    expect(tiers, contains("'Loyalty Tiers'"));
    expect(tiers, contains("'YOUR LOYALTY TIER'"));
    expect(tiers, contains('store.loyaltyEarningMultiplierLabel'));
    expect(tiers, contains('...store.tiers.map'));
  });

  test('Task 246B-10A separates paid-member and loyalty multipliers', () {
    final store = File(
      'lib/core/membership/customer_membership_store.dart',
    ).readAsStringSync();

    expect(store, contains('bool get isActive => _active || _previewMember;'));
    expect(
        store, contains('double get earningMultiplier => isActive ? 2 : 1;'));
    expect(store, contains('double get loyaltyEarningMultiplier'));
    expect(store, contains('loyaltyEarningMultiplierLabel'));
    expect(store, contains('repository.membershipTiers()'));
  });
}
