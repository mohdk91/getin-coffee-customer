import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 183 obtains delivery credentials only from Laravel', () {
    final screen =
        File('lib/features/orders/live_order_detail_screen.dart').readAsStringSync();
    final service =
        File('lib/core/orders/live_order_lifecycle_service.dart').readAsStringSync();

    expect(screen, contains('_service.issueDeliveryPin(widget.orderId)'));
    expect(screen, contains('_service.issueDeliveryQr(widget.orderId)'));
    expect(screen, contains('pin!.pin'));
    expect(screen, contains('qr!.payload'));
    expect(screen, contains('Requesting early is safely rejected by the server'));
    expect(service, contains("_idempotencyKey('delivery-pin'"));
    expect(service, contains("_idempotencyKey('delivery-qr'"));
    expect(screen, isNot(contains("code: order.deliveryCode")));
  });
}
