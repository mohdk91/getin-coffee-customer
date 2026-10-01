import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 178 keeps lifecycle actions behind authenticated Laravel APIs', () {
    final service = File('lib/core/orders/live_order_lifecycle_service.dart')
        .readAsStringSync();
    final repository = File('lib/core/orders/customer_orders_api_repository.dart')
        .readAsStringSync();

    expect(service, contains('LiveOrderDetail.fromJson'));
    expect(service, contains('loadDeliveryTimeline'));
    expect(service, contains("_idempotencyKey('cancel'"));
    expect(service, contains("_idempotencyKey('refund'"));
    expect(service, contains("_idempotencyKey('delivery-pin'"));
    expect(service, contains("_idempotencyKey('delivery-qr'"));
    expect(repository, contains('/delivery-timeline'));
    expect(repository, contains('/cancel'));
    expect(repository, contains('/refunds'));
    expect(repository, contains('/delivery-pin'));
    expect(repository, contains('/delivery-qr'));
  });
}
