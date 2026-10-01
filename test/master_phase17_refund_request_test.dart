import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 182 keeps refund amount server-calculated', () {
    final screen =
        File('lib/features/orders/live_order_detail_screen.dart').readAsStringSync();
    final service =
        File('lib/core/orders/live_order_lifecycle_service.dart').readAsStringSync();
    final repository =
        File('lib/core/orders/customer_orders_api_repository.dart').readAsStringSync();

    expect(screen, contains('_service.requestRefund'));
    expect(screen, contains('GETIN calculates the refundable amount on the server'));
    expect(service, contains("_idempotencyKey('refund'"));
    expect(repository, contains("body:{'reason':reason}"));
    expect(repository, isNot(contains("'amount':")));
    expect(screen, contains('refund.amount'));
  });
}
