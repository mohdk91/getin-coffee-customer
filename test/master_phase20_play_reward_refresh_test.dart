import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 209 refreshes loyalty and voucher state after live play', () {
    final source = File(
      'lib/features/play/getin_play_screen.dart',
    ).readAsStringSync();

    expect(source, contains("import '../../core/vouchers/customer_voucher_store.dart';"));
    expect(source, contains('await CustomerRewardsStore.instance.refresh();'));
    expect(source, contains('await CustomerVoucherStore.instance.refresh();'));
    expect(
      RegExp(r'CustomerRewardsStore\.instance\.refresh\(\);').allMatches(source).length,
      greaterThanOrEqualTo(2),
    );
  });
}
