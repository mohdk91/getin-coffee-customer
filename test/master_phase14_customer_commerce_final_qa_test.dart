import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/features/checkout/checkout_screen.dart';

void main() {
  test('Master Phase 14 production wiring stays coherent end to end', () {
    expect(const CheckoutScreen(), isA<CheckoutScreen>());
    final home = File('lib/features/home/home_shell.dart').readAsStringSync();
    final menu = File('lib/features/menu/menu_screen.dart').readAsStringSync();
    final cart = File('lib/features/cart/cart_controller.dart').readAsStringSync();
    final checkout = File('lib/features/checkout/checkout_screen.dart').readAsStringSync();
    final service = File('lib/core/orders/laravel_checkout_order_service.dart').readAsStringSync();
    final orders = File('lib/features/orders/orders_screen.dart').readAsStringSync();
    final content = File('lib/core/content/mobile_app_content_models.dart').readAsStringSync();

    expect(home, contains('refreshBranch(_branch.id)'));
    expect(menu, contains('categoriesForBranch(widget.branch.id)'));
    expect(menu, contains('catalogProduct: product'));
    expect(content, contains("json['menu_collections']"));
    expect(cart, contains('bool get hasServerIdentity'));
    expect(checkout, contains('LaravelCheckoutOrderService'));
    expect(checkout, isNot(contains(
      'final CheckoutOrderService _orderService = DemoCheckoutOrderService.instance',
    )));
    expect(service, contains("'product_id': productId"));
    expect(service, contains("'quantity': line.quantity"));
    expect(service, isNot(contains("'unit_price'")));
    expect(service, isNot(contains("'subtotal'")));
    expect(service, contains('idempotencyKey: draft.clientRequestId'));
    expect(orders, contains("import '../../core/auth/customer_auth_store.dart';"));
    expect(orders, contains("import '../../core/data/customer_repository.dart';"));
    expect(orders, contains("import '../../core/orders/customer_orders_api_repository.dart';"));
    expect(orders, contains('CustomerOrdersApiRepository'));
    expect(orders, contains('GetinOrder.fromApiSummary'));
    expect(orders, contains('return controller.createdOrders;'));
  });
}
