import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 238 keeps Phase 23 Stripe card payments production authoritative', () {
    final stripe = File('lib/core/payments/customer_stripe_payment_service.dart')
        .readAsStringSync();
    final store = File('lib/core/payments/customer_payment_method_store.dart')
        .readAsStringSync();
    final checkout = File('lib/features/checkout/checkout_screen.dart')
        .readAsStringSync();
    final orderService =
        File('lib/core/orders/laravel_checkout_order_service.dart').readAsStringSync();
    final paymentScreen =
        File('lib/features/payments/payment_methods_screen.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('flutter_stripe: ^11.5.0'));
    expect(stripe, contains('SetupPaymentSheetParameters('));
    expect(stripe, contains("paymentMethodOrder: const <String>['card']"));
    expect(stripe, contains('CardBrandAcceptance.allowed('));
    expect(stripe, contains('CardBrandCategory.visa'));
    expect(stripe, contains('CardBrandCategory.mastercard'));
    expect(store, contains('_repository!.paymentMethods()'));
    expect(paymentScreen, contains('presentSetupSheet(session)'));
    expect(checkout, contains('presentCheckoutSheet(session)'));
    expect(checkout, contains('draft = draft.withPaymentSession(session.paymentSessionId)'));
    expect(orderService, contains("payload['payment_session_id'] = draft.paymentSessionId"));
    expect(checkout.indexOf('presentCheckoutSheet(session)'),
        lessThan(checkout.indexOf('.createOrder(draft)')));
    expect(paymentScreen,
        contains('raw card number and CVC never pass through the GETIN API'));
    expect(stripe, isNot(contains('CardField(')));
    expect(orderService, isNot(contains('payment_token_reference')));
  });
}
