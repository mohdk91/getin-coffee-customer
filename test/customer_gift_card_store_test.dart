import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/gift_cards/customer_gift_card_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await CustomerGiftCardStore.instance.resetForTesting();
  });

  test('demo wallet starts with EGP 240 and a received card', () async {
    await CustomerGiftCardStore.initialize();
    final store = CustomerGiftCardStore.instance;

    expect(store.balance, 240);
    expect(store.receivedCards.any((card) => card.code == 'GETIN100'), isTrue);
  });

  test('redeeming received demo card adds it to balance once', () async {
    await CustomerGiftCardStore.initialize();
    final store = CustomerGiftCardStore.instance;

    expect(await store.redeemCode('GETIN100'), GiftCardRedeemResult.success);
    expect(store.balance, 340);
    expect(
      await store.redeemCode('GETIN100'),
      GiftCardRedeemResult.alreadyRedeemed,
    );
    expect(store.balance, 340);
  });

  test('buying a gift card creates sent history without changing balance',
      () async {
    await CustomerGiftCardStore.initialize();
    final store = CustomerGiftCardStore.instance;

    final before = store.balance;
    final card = await store.purchase(
      amount: 250,
      recipientName: 'Test Friend',
      recipientContact: 'friend@example.com',
      message: 'Enjoy',
      deliveryDate: DateTime.now(),
    );

    expect(card.status, GiftCardStatus.sent);
    expect(store.sentCards.any((item) => item.id == card.id), isTrue);
    expect(store.balance, before);
  });

  test('checkout spend cannot deduct more than wallet balance', () async {
    await CustomerGiftCardStore.initialize();
    final store = CustomerGiftCardStore.instance;

    final applied = await store.spendBalance(500);
    expect(applied, 240);
    expect(store.balance, 0);
  });
}
