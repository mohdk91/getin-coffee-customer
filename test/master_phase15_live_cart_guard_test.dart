import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 164 revalidates availability and price before live cart mutation', () {
    final source = File('lib/features/product/live_product_detail_screen.dart')
        .readAsStringSync();

    final saveStart = source.indexOf('Future<void> _saveToCart()');
    final availability = source.indexOf('loadAvailability(', saveStart);
    final quote = source.indexOf('quoteProduct(', saveStart);
    final cartMutation = source.indexOf('cart.addOrMerge(item)', saveStart);

    expect(saveStart, greaterThanOrEqualTo(0));
    expect(availability, greaterThan(saveStart));
    expect(quote, greaterThan(availability));
    expect(cartMutation, greaterThan(quote));
    expect(source, contains('unitPrice: freshQuote.unitTotal'));
    expect(source, contains('optionValueIds: configuration.optionValueIds'));
    expect(source, contains('Nothing was added.'));
  });
}
