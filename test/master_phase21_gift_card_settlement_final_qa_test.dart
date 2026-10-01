import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 220 keeps Phase 21 gift-card settlement server authoritative', () {
    final wallet = File(
      'lib/core/gift_cards/customer_gift_card_store.dart',
    ).readAsStringSync();
    final quote = File(
      'lib/core/orders/live_checkout_quote_service.dart',
    ).readAsStringSync();
    final orderService = File(
      'lib/core/orders/laravel_checkout_order_service.dart',
    ).readAsStringSync();
    final detailModels = File(
      'lib/core/orders/live_order_models.dart',
    ).readAsStringSync();
    final detailScreen = File(
      'lib/features/orders/live_order_detail_screen.dart',
    ).readAsStringSync();
    final walletScreen = File(
      'lib/features/gift_cards/gift_cards_screen.dart',
    ).readAsStringSync();

    expect(wallet, contains('currentBalance'));
    expect(wallet, contains('refreshTransactions'));
    expect(quote, contains("'gift_card_id': giftCardId"));
    expect(quote, contains("data['amount_due']"));
    expect(orderService, contains("'gift_card_id': draft.giftCardId"));
    expect(orderService, isNot(contains('gift_card_amount')));
    expect(detailModels, contains('LiveGiftCardSettlement'));
    expect(detailModels, contains("json['gift_card']"));
    expect(detailScreen, contains('Gift card restored'));
    expect(detailScreen, contains('CustomerGiftCardStore.instance.refresh()'));
    expect(walletScreen, contains('View balance activity'));
  });
}
