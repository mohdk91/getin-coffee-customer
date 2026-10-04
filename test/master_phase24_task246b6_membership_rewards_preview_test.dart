import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-6 keeps authenticated membership server-authoritative', () {
    final store = File(
      'lib/core/membership/customer_membership_store.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/membership/membership_screen.dart',
    ).readAsStringSync();

    expect(store, contains('CustomerAuthStore.instance.isAuthenticated'));
    expect(store, contains('store._handleAuthChanged'));
    expect(store, contains('_loadGuestMembership()'));
    expect(store, contains('repository.membershipTiers()'));
    expect(screen, contains('if (CustomerMembershipStore.instance.usesApi)'));
    expect(screen, contains('return _LiveMembershipScreen'));
  });

  test('Task 246B-6 supports both join and joined membership states', () {
    final screen = File(
      'lib/features/membership/membership_screen.dart',
    ).readAsStringSync();
    final joined = File(
      'lib/features/membership/membership_joined_preview.dart',
    ).readAsStringSync();

    expect(screen, contains('if (membership.isActive)'));
    expect(screen, contains('MembershipJoinedPreview('));
    expect(screen, contains('store.activate(billingCycle: billingCycle)'));
    expect(screen, isNot(contains('Demo membership activated')));
    expect(joined, contains("'Green Member'"));
    expect(joined, contains("'Membership active'"));
    expect(joined, contains("'1.5× Stars'"));
    expect(joined, contains('CustomerRewardsStore.instance'));
    expect(joined, contains('CustomerStampCardStore.instance'));
  });

  test(
      'Task 246B-6 shows Stars and 3 of 7 stamp progress with completed-order history',
      () {
    final rewardsScreen = File(
      'lib/features/rewards/rewards_screen.dart',
    ).readAsStringSync();
    final rewardsStore = File(
      'lib/core/rewards/customer_rewards_store.dart',
    ).readAsStringSync();
    final stampStore = File(
      'lib/core/rewards/customer_stamp_card_store.dart',
    ).readAsStringSync();

    expect(rewardsScreen, contains('_MembershipEarningCard('));
    expect(
        rewardsScreen, contains(r"'$current / ${stampStore.requiredStamps}'"));
    expect(rewardsStore, contains("title: 'Order GC-10540 completed'"));
    expect(rewardsStore,
        contains("subtitle: 'Stars added after your completed order'"));
    expect(stampStore, contains('_currentStamps = 3'));
    expect(stampStore, contains('?? 3'));
  });

  test('Task 246B-6 removes implementation wording from reward checkout UI',
      () {
    final picker = File(
      'lib/features/rewards/reward_picker_sheet.dart',
    ).readAsStringSync();

    expect(picker, contains('Eligibility is confirmed at checkout.'));
    expect(picker, isNot(contains('Laravel will confirm')));
  });
}
