import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 158 uses Laravel order history in API mode without demo fixtures', () {
    final orders = File('lib/features/orders/orders_screen.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();

    expect(orders, contains('CustomerOrdersApiRepository'));
    expect(orders, contains('Future<void> refreshFromApi()'));
    expect(orders, contains('GetinOrder.fromApiSummary'));
    expect(orders, contains('if (controller.usesApi)'));
    expect(orders, contains('return controller.createdOrders;'));
    expect(main, contains('CustomerOrdersController.initialize(CustomerAuthStore.instance.context)'));
  });
}
