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
    expect(checkout, contains('Stripe PaymentSheet securely confirms Visa/Mastercard'));
    expect(
      checkout,
      contains('Raw card number and CVC never pass through GETIN'),
    );
    expect(cart, contains('void completeServerOrder()'));
    expect(confirmation, contains('if (earnedStars > 0)'));
  });
}
