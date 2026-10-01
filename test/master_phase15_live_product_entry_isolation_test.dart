import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 166 keeps API cart editing on live product identity', () {
    final cart = File('lib/features/cart/cart_screen.dart').readAsStringSync();
    final detail = File('lib/features/product/product_detail_screen.dart')
        .readAsStringSync();

    expect(cart, contains('if (catalog.usesApi)'));
    expect(cart, contains('final branchId = item.branchId;'));
    expect(cart, contains('final productId = item.productId;'));
    expect(cart, contains('catalog.loadProduct(branchId, productId)'));
    expect(cart, contains('catalogProduct: product'));
    expect(cart, contains('branchId: branchId'));
    expect(cart, contains('if (!CustomerCatalogStore.instance.usesApi)'));
    expect(detail, contains('CustomerCatalogStore.instance.usesApi'));
    expect(detail, contains('LiveProductDetailScreen('));
  });
}
