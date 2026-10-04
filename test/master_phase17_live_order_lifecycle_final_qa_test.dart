import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 186 keeps post-order lifecycle server authoritative end to end',
      () {
    final models =
        File('lib/core/orders/live_order_models.dart').readAsStringSync();
    final service = File('lib/core/orders/live_order_lifecycle_service.dart')
        .readAsStringSync();
    final repository =
        File('lib/core/orders/customer_orders_api_repository.dart')
            .readAsStringSync();
    final orders =
        File('lib/features/orders/orders_screen.dart').readAsStringSync();
    final live = File('lib/features/orders/live_order_detail_screen.dart')
        .readAsStringSync();

    expect(models, contains('class LiveOrderDetail'));
    expect(models, contains('class LiveDeliveryPin'));
    expect(models, contains('class LiveDeliveryQr'));
    expect(models, contains('class LiveRefundRequest'));

    expect(service, contains('loadOrder(int orderId)'));
    expect(service, contains('loadDeliveryTimeline(int orderId)'));
    expect(service, contains('cancelOrder'));
    expect(service, contains('requestRefund'));
    expect(service, contains('issueDeliveryPin'));
    expect(service, contains('issueDeliveryQr'));

    expect(repository, contains('/orders/\$orderId'));
    expect(repository, contains('/delivery-timeline'));
    expect(repository, contains("body:{'reason':reason}"));
    expect(repository, isNot(contains("'amount':")));

    expect(orders, contains('order.apiOrderId != null'));
    expect(orders, contains('orderId: order.apiOrderId!'));
    expect(
      live,
      contains('GETIN will calculate the eligible refundable amount.'),
    );
    expect(
      live,
      contains(
          'When your driver arrives, request a one-time PIN or QR to confirm the handover.'),
    );
    expect(live, contains('_service.issueDeliveryPin(widget.orderId)'));
    expect(live, contains('_service.issueDeliveryQr(widget.orderId)'));
    expect(live, contains('await _refreshAuthoritativeState();'));
    expect(live, isNot(contains('_PreviewDriverTracker')));
    expect(live, isNot(contains('deliveryCode ??')));
    expect(live, isNot(contains("'amount':")));
  });
}
