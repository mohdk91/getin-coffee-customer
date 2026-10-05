import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-11K keeps every bottom nav label on one responsive line', () {
    final shell = File('lib/features/home/home_shell.dart').readAsStringSync();

    expect(shell, contains("'Membership'"));
    expect(shell, contains('fit: BoxFit.scaleDown'));
    expect(shell, contains('maxLines: 1'));
    expect(shell, contains('softWrap: false'));
    expect(shell, isNot(contains('maxLines: 2,\n                overflow')));
  });

  test('Task 246B-11K gives Often Ordered With its own clickable plus action',
      () {
    final detail = File(
      'lib/features/product/live_product_detail_screen.dart',
    ).readAsStringSync();
    final merchandising = File(
      'lib/features/product/product_merchandising_preview.dart',
    ).readAsStringSync();

    expect(detail, contains('Future<void> _quickAddPairing'));
    expect(detail, contains('onQuickAdd: _quickAddPairing'));
    expect(detail, contains('loadAvailability('));
    expect(detail, contains('CustomerCatalogStore.instance.quoteProduct'));
    expect(detail, contains('unitPrice: freshQuote.unitTotal'));
    expect(detail, contains('cart.addOrMerge(item)'));

    expect(merchandising,
        contains('final ValueChanged<CatalogProduct> onQuickAdd'));
    expect(merchandising, contains('onTap: adding ? null : onQuickAdd'));
    expect(merchandising, contains("label: adding"));
    expect(merchandising, contains("'Add \${product.name} to cart'"));
  });

  test('Task 246B-11K never silently chooses configurable cross-sell options',
      () {
    final detail = File(
      'lib/features/product/live_product_detail_screen.dart',
    ).readAsStringSync();

    expect(
      detail,
      contains('if (product.isVariable || product.optionGroups.isNotEmpty)'),
    );
    expect(detail, contains('await _openPairing(product)'));
    expect(detail, contains('optionValueIds: const <int>[]'));
  });
}
