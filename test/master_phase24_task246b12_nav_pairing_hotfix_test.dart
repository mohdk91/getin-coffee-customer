import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-12 keeps Membership on one responsive nav line', () {
    final shell = File('lib/features/home/home_shell.dart').readAsStringSync();

    expect(shell, contains("'Membership'"));
    expect(shell, contains('fit: BoxFit.scaleDown'));
    expect(shell, contains('maxLines: 1'));
    expect(shell, contains('softWrap: false'));
  });

  test('Task 246B-12 makes production Often Ordered With plus interactive', () {
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

    expect(
      merchandising,
      contains('final ValueChanged<CatalogProduct> onQuickAdd;'),
    );
    expect(merchandising, contains('onTap: adding ? null : onQuickAdd'));
    expect(merchandising, contains("'Add \${product.name} to cart'"));
    expect(merchandising, contains('width: 36'));
    expect(merchandising, contains('height: 36'));
  });

  test('Task 246B-12 does not silently choose configurable pairing options',
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
