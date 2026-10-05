import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 234 adds native Stripe PaymentSheet without raw card handling', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final service = File('lib/core/payments/customer_stripe_payment_service.dart')
        .readAsStringSync();
    final repository = File('lib/core/orders/customer_checkout_api_repository.dart')
        .readAsStringSync();
    final mainActivity = Directory('android/app/src/main')
        .listSync(recursive: true)
        .whereType<File>()
        .firstWhere((file) => file.path.endsWith('MainActivity.kt'))
        .readAsStringSync();
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

    expect(pubspec, contains('flutter_stripe: ^11.5.0'));
    expect(service, contains('SetupPaymentSheetParameters('));
    expect(service, contains("paymentMethodOrder: const <String>['card']"));
    expect(service, contains('setupIntentClientSecret'));
    expect(service, contains('paymentIntentClientSecret'));
    expect(repository, contains('/checkout/payment-session'));
    expect(mainActivity, contains('FlutterFragmentActivity'));
    expect(project, contains('IPHONEOS_DEPLOYMENT_TARGET = 15.5;'));
    expect(service, isNot(contains('cardNumber')));
    expect(service, isNot(contains('cvc')));
  });
}
