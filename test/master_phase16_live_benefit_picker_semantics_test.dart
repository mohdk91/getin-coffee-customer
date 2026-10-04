import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 175 keeps API benefit pickers server-authoritative', () {
    final voucherPicker = File(
      'lib/features/vouchers/voucher_picker_sheet.dart',
    ).readAsStringSync();
    final rewardPicker = File(
      'lib/features/rewards/reward_picker_sheet.dart',
    ).readAsStringSync();

    expect(
      voucherPicker,
      contains('if (!vouchers.usesApi && eligible.isNotEmpty)'),
    );
    expect(voucherPicker, contains('serverManaged:'));
    expect(
      voucherPicker,
      contains('vouchers.usesApi || voucher.serverManaged'),
    );
    expect(voucherPicker, isNot(contains('Laravel will confirm')));
    expect(
      voucherPicker,
      contains(
          'Eligible for this cart. Final saving is confirmed at checkout.'),
    );
    expect(
      rewardPicker,
      contains('Eligibility is confirmed at checkout.'),
    );
    expect(rewardPicker, isNot(contains('Laravel will confirm')));
  });
}
