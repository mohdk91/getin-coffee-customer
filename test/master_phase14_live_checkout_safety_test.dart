import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 157 never hard-wires demo checkout in API mode', () {
    final checkout = File('lib/features/checkout/checkout_screen.dart').readAsStringSync();
    final cart = File('lib/features/cart/cart_controller.dart').readAsStringSync();
    final confirmation = File('lib/features/orders/order_confirmation_screen.dart').readAsStringSync();

    expect(checkout, contains('LaravelCheckoutOrderService'));
    expect(checkout, contains('item.hasServerIdentity'));
    expect(checkout, contains('completeServerOrder()'));
    expect(checkout, contains("result.currency ?? draft.currency"));
    expect(checkout, contains("delivery && !_usesApi ? '4728' : null"));
    expect(checkout, contains('payment as pending'));
    expect(cart, contains('void completeServerOrder()'));
    expect(confirmation, contains('if (earnedStars > 0)'));
  });
}
