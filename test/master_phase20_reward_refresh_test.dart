import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 205 refreshes authoritative loyalty after reward redemption', () {
    final store = File(
      'lib/core/rewards/customer_rewards_store.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/rewards/rewards_screen.dart',
    ).readAsStringSync();

    expect(store, contains('await _repository!.redeemReward(rewardId)'));
    expect(store, contains('await refresh();'));
    expect(store, isNot(contains('_redeemedRewards.insert(0, redemption);\n    await _refreshLoyaltyApi();')));
    expect(screen, contains('_RewardsAuthorityNotice(live: _rewards.usesApi)'));
    expect(screen, contains('confirmed by your GETIN account'));
  });
}
