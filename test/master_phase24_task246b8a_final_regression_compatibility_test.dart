import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'Task 246B-8A keeps the fixed Home viewport without stale layout markers',
      () {
    final source = File('lib/features/home/home_shell.dart').readAsStringSync();

    expect(source, contains('child: SizedBox('));
    expect(source, contains('height: 68'));
    expect(source, isNot(contains('// BoxConstraints(minHeight: 64)')));
  });

  test(
      'Task 246B-8A keeps Orders authoritative without customer-facing server copy',
      () {
    final source = File(
      'lib/features/orders/live_order_detail_screen.dart',
    ).readAsStringSync();

    expect(source, contains('_service.requestRefund'));
    expect(source, contains('_service.issueDeliveryPin(widget.orderId)'));
    expect(source, contains('_service.issueDeliveryQr(widget.orderId)'));
    expect(
      source,
      contains('GETIN will calculate the eligible refundable amount.'),
    );
    expect(source, isNot(contains('refundable amount on the server')));
  });

  test(
      'Task 246B-8A keeps reward authority in behavior and customer-ready copy',
      () {
    final source = File(
      'lib/features/rewards/reward_picker_sheet.dart',
    ).readAsStringSync();

    expect(source, contains('rewards.usesApi'));
    expect(source, contains('Eligibility is confirmed at checkout.'));
    expect(source, isNot(contains('Laravel will confirm')));
  });
}
