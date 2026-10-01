import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 219 sends only gift card identity and trusts Laravel settlement', () {
    final quote = File(
      'lib/core/orders/live_checkout_quote_service.dart',
    ).readAsStringSync();
    final service = File(
      'lib/core/orders/laravel_checkout_order_service.dart',
    ).readAsStringSync();
    final checkout = File(
      'lib/features/checkout/checkout_screen.dart',
    ).readAsStringSync();

    expect(quote, contains("'gift_card_id': giftCardId"));
    expect(quote, contains("data['amount_due']"));
    expect(quote, contains("giftCard['applied']"));
    expect(service, contains("'gift_card_id': draft.giftCardId"));
    expect(service, isNot(contains('gift_card_amount')));
    expect(checkout, contains('_liveQuote?.giftCardApplied'));
    expect(checkout, contains('_liveQuote?.amountDue'));
    expect(checkout, contains('CustomerGiftCardStore.instance.refresh()'));
    expect(
      checkout,
      isNot(contains('cannot be spent in live checkout until Laravel exposes')),
    );
  });
}
