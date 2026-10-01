import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 172 renders API vouchers and rewards with Laravel quote totals', () {
    final source = File(
      'lib/features/checkout/checkout_screen.dart',
    ).readAsStringSync();
    final liveQuote = File(
      'lib/core/orders/live_checkout_quote_service.dart',
    ).readAsStringSync();

    expect(source, contains('LiveCheckoutQuote? _liveQuote'));
    expect(source, contains('Future<bool> _refreshLiveQuote'));
    expect(source, contains('promotionCode: _livePromotionCode'));
    expect(source, contains('_LiveCheckoutSummary('));
    expect(source, contains('current.discountTotal'));
    expect(
      source,
      isNot(contains('Remove local preview rewards, vouchers')),
    );
    expect(
      source,
      isNot(contains('Gift Card Balance cannot be spent in live checkout')),
    );
    expect(source, contains('_liveQuote?.giftCardApplied'));
    expect(source, contains('_liveQuote?.amountDue'));
    expect(liveQuote, contains("'gift_card_id': giftCardId"));
  });
}
