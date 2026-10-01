import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 169 uses the Laravel-issued voucher for live reward redemptions', () {
    final source = File(
      'lib/core/rewards/customer_rewards_store.dart',
    ).readAsStringSync();

    expect(source, contains("voucher['voucher_code']"));
    expect(source, contains("voucherStatus == 'active'"));
    expect(source, isNot(contains("statusText.contains('fulfill')")));
    expect(
      source,
      contains('without returning its issued voucher code'),
    );
  });
}
