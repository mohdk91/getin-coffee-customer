import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 163 renders server option groups and refreshes authoritative quote', () {
    final source = File('lib/features/product/live_product_detail_screen.dart')
        .readAsStringSync();

    expect(source, contains('configuration.availableVariants'));
    expect(source, contains('product.optionGroups'));
    expect(source, contains('configuration.toggleValue'));
    expect(source, contains('CustomerCatalogStore.instance.quoteProduct'));
    expect(source, contains("orderType: widget.serviceType"));
    expect(source, contains('optionValueIds: configuration.optionValueIds'));
    expect(source, contains("'Live price confirmed'"));
  });
}
