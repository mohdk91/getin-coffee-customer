import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 236 confirms Stripe before live order creation', () {
    final checkout = File('lib/features/checkout/checkout_screen.dart').readAsStringSync();
    final draft = File('lib/core/orders/checkout_order_draft.dart').readAsStringSync();
    final service = File('lib/core/orders/laravel_checkout_order_service.dart').readAsStringSync();

    final paymentSession = checkout.indexOf('createCheckoutSession(');
    final paymentSheet = checkout.indexOf('presentCheckoutSheet(session)');
    final orderCreate = checkout.indexOf('.createOrder(draft)');
    expect(paymentSession, greaterThan(-1));
    expect(paymentSheet, greaterThan(paymentSession));
    expect(orderCreate, greaterThan(paymentSheet));
    expect(checkout, contains('Your cart and checkout benefits are unchanged'));
    expect(draft, contains('final String? paymentSessionId'));
    expect(draft, contains('withPaymentSession'));
    expect(service, contains("payload['payment_session_id'] = draft.paymentSessionId"));
    expect(service, isNot(contains('payment_token_reference')));
    expect(checkout, isNot(contains('card payment pending')));
  });
}
