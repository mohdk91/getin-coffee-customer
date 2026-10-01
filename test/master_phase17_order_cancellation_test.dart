import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 181 sends only reason and idempotency to server cancellation', () {
    final screen =
        File('lib/features/orders/live_order_detail_screen.dart').readAsStringSync();
    final service =
        File('lib/core/orders/live_order_lifecycle_service.dart').readAsStringSync();
    final repository =
        File('lib/core/orders/customer_orders_api_repository.dart').readAsStringSync();

    expect(screen, contains('_service.cancelOrder'));
    expect(screen, contains('GETIN verifies cancellation eligibility'));
    expect(service, contains("_idempotencyKey('cancel'"));
    expect(repository, contains("body:{'reason':reason}"));
    expect(screen, isNot(contains("'status': 'cancelled'")));
  });
}
