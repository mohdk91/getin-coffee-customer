import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 235 keeps live saved cards Stripe authoritative', () {
    final store = File('lib/core/payments/customer_payment_method_store.dart')
        .readAsStringSync();
    final screen = File('lib/features/payments/payment_methods_screen.dart')
        .readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    final sync = File('lib/core/auth/customer_account_sync.dart').readAsStringSync();

    expect(store, contains('_repository!.paymentMethods()'));
    expect(store, contains('setDefaultPaymentMethod('));
    expect(store, contains('deletePaymentMethod('));
    expect(store, contains("id.startsWith('pm_')"));
    expect(store, contains('Live cards must be added through Stripe PaymentSheet.'));
    expect(screen, contains('createSetupSession()'));
    expect(screen, contains('presentSetupSheet(session)'));
    expect(screen, contains('raw card number and CVC never pass through the GETIN API'));
    expect(main, contains('CustomerPaymentMethodStore.initialize(CustomerAuthStore.instance.context)'));
    expect(sync, contains('CustomerPaymentMethodStore.instance.refresh'));
  });
}
