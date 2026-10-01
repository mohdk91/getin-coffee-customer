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
    expect(voucherPicker, contains('serverManaged: vouchers.usesApi'));
    expect(
      voucherPicker,
      contains('Laravel will confirm eligibility and the final saving.'),
    );
    expect(
      voucherPicker,
      contains('Laravel will verify this voucher and calculate the final saving.'),
    );
    expect(
      rewardPicker,
      contains('Laravel will confirm it against this checkout.'),
    );
  });
}
