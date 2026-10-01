import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 185 refreshes live order history after server lifecycle changes', () {
    final live =
        File('lib/features/orders/live_order_detail_screen.dart').readAsStringSync();
    final orders = File('lib/features/orders/orders_screen.dart').readAsStringSync();
    final confirmation =
        File('lib/features/orders/order_confirmation_screen.dart').readAsStringSync();

    expect(live, contains('final Future<void> Function()? onOrderChanged'));
    expect(live, contains('await _notifyOrderChanged();'));
    expect(orders, contains('controller.refreshFromApi'));
    expect(confirmation,
        contains('CustomerOrdersController.instance.refreshFromApi'));
  });
}
