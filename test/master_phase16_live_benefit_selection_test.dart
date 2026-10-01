import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 170 keeps API benefit selection non-monetary and single-code', () {
    final source = File(
      'lib/features/cart/cart_controller.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('if (CustomerRewardsStore.instance.usesApi) {\n      return 0;'),
    );
    expect(
      source,
      contains('if (CustomerVoucherStore.instance.usesApi) {\n      return 0;'),
    );
    expect(source, contains('vouchers.usesApi && appliedReward != null'));
    expect(source, contains('rewards.usesApi && appliedVoucher != null'));
    expect(source, contains('Laravel will verify this voucher'));
    expect(source, contains('Laravel will verify this reward'));
  });
}
