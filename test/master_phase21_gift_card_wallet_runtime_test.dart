import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 218 uses current server gift-card balance and transactions', () {
    final store = File(
      'lib/core/gift_cards/customer_gift_card_store.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/core/engagement/customer_engagement_api_repository.dart',
    ).readAsStringSync();

    expect(store, contains('currentBalance'));
    expect(store, contains('sum + card.currentBalance'));
    expect(store, contains('CustomerGiftCardTransaction.fromApi'));
    expect(store, contains('refreshTransactions'));
    expect(store, contains('selectForCheckout'));
    expect(repository, contains('/v1/customer/gift-cards/\$giftCardId/transactions'));
  });
}
