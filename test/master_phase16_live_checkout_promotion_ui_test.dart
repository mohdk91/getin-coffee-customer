import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 172 renders API vouchers and rewards with Laravel quote totals', () {
    final source = File(
      'lib/features/checkout/checkout_screen.dart',
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
      contains('Gift Card Balance cannot be spent in live checkout'),
    );
  });
}
