import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 179 routes API orders into authoritative live detail', () {
    final orders = File('lib/features/orders/orders_screen.dart').readAsStringSync();
    final confirmation =
        File('lib/features/orders/order_confirmation_screen.dart').readAsStringSync();
    final live =
        File('lib/features/orders/live_order_detail_screen.dart').readAsStringSync();

    expect(orders, contains('controller.usesApi && order.apiOrderId != null'));
    expect(orders, contains('LiveOrderDetailScreen'));
    expect(confirmation, contains('order.apiOrderId != null'));
    expect(live, contains('LiveOrderLifecycleService'));
    expect(live, contains('loadOrder(widget.orderId)'));
    expect(live, contains('detail.items'));
    expect(live, contains('detail.paymentStatus'));
  });
}
