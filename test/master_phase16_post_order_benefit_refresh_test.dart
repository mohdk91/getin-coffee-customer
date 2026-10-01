import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 174 refreshes server benefit state only after live order success', () {
    final checkout = File(
      'lib/features/checkout/checkout_screen.dart',
    ).readAsStringSync();
    final rewards = File(
      'lib/core/rewards/customer_rewards_store.dart',
    ).readAsStringSync();

    expect(checkout, contains('_cart.completeServerOrder();'));
    expect(checkout, contains('CustomerVoucherStore.instance.refresh()'));
    expect(checkout, contains('CustomerRewardsStore.instance.refresh()'));
    expect(rewards, contains('Future<void> refresh() async'));
    expect(
      checkout,
      contains('instead of marking rewards/vouchers as used locally'),
    );
  });
}
