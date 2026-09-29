import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/payments/customer_payment_method_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await CustomerPaymentMethodStore.instance.resetForTesting();
  });

  test('demo seed provides active default and expired card state', () async {
    await CustomerPaymentMethodStore.initialize();

    final store = CustomerPaymentMethodStore.instance;
    expect(store.methods, hasLength(3));
    expect(store.defaultMethod?.last4, '5008');
    expect(store.checkoutMethod?.last4, '5008');
    expect(store.methods.any((method) => method.isExpired), isTrue);
  });

  test('adds tokenized demo card without a full card number', () async {
    await CustomerPaymentMethodStore.initialize();

    final added =
        await CustomerPaymentMethodStore.instance.addDemoTokenizedCard(
      brand: 'VISA',
      last4: '7788',
      expiryMonth: 12,
      expiryYear: 2030,
      makeDefault: true,
    );

    expect(added.last4, '7788');
    expect(added.providerTokenRef, startsWith('demo_pm_'));
    expect(added.toJson().keys, isNot(contains('cardNumber')));
    expect(added.toJson().keys, isNot(contains('cvv')));
    expect(CustomerPaymentMethodStore.instance.defaultMethod?.id, added.id);
  });

  test('expired method cannot become default or checkout selection', () async {
    await CustomerPaymentMethodStore.initialize();

    final store = CustomerPaymentMethodStore.instance;
    final expired = store.methods.firstWhere((method) => method.isExpired);

    expect(await store.setDefault(expired.id), isFalse);
    expect(await store.selectForCheckout(expired.id), isFalse);
    expect(store.checkoutMethod?.isExpired, isFalse);
  });

  test('removing default promotes another active card', () async {
    await CustomerPaymentMethodStore.initialize();

    final store = CustomerPaymentMethodStore.instance;
    final originalDefault = store.defaultMethod!;
    await store.remove(originalDefault.id);

    expect(store.defaultMethod, isNotNull);
    expect(store.defaultMethod?.id, isNot(originalDefault.id));
    expect(store.defaultMethod?.isExpired, isFalse);
  });
}
