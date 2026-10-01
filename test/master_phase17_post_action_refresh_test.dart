import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 184 reloads order state from Laravel after lifecycle actions', () {
    final screen =
        File('lib/features/orders/live_order_detail_screen.dart').readAsStringSync();

    expect(screen, contains('Future<void> _refreshAuthoritativeState()'));
    expect(screen, contains('await _service.loadOrder(widget.orderId)'));
    expect(screen, contains('await _service.loadDeliveryTimeline(widget.orderId)'));
    expect(screen, contains('await _service.cancelOrder'));
    expect(screen, contains('await _refreshAuthoritativeState();'));
    expect(screen, isNot(contains("status = 'cancelled'")));
    expect(screen, isNot(contains('GetinOrderStatus.cancelled')));
  });
}
