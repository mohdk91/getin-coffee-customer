import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 155 carries Laravel identities from live catalog into the cart', () {
    final cart = File('lib/features/cart/cart_controller.dart').readAsStringSync();
    final detail = File('lib/features/product/product_detail_screen.dart').readAsStringSync();
    final menu = File('lib/features/menu/menu_screen.dart').readAsStringSync();
    final draft = File('lib/core/orders/checkout_order_draft.dart').readAsStringSync();

    expect(cart, contains('final int? branchId;'));
    expect(cart, contains('final int? productId;'));
    expect(cart, contains('final List<int> optionValueIds;'));
    expect(cart, contains('bool get hasServerIdentity'));
    expect(detail, contains('final CatalogProduct? catalogProduct;'));
    expect(detail, contains('_serverOptionValueIds'));
    expect(menu, contains('catalogProduct: product'));
    expect(draft, contains("'product_id': productId"));
    expect(draft, contains("'option_value_ids': optionValueIds"));
  });
}
