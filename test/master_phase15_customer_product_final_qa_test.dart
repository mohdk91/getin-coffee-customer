import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 167 keeps live product commerce server authoritative', () {
    final models = File('lib/core/catalog/customer_catalog_models.dart')
        .readAsStringSync();
    final repository = File('lib/core/catalog/customer_catalog_repository.dart')
        .readAsStringSync();
    final configuration =
        File('lib/features/product/live_product_configuration.dart')
            .readAsStringSync();
    final screen = File('lib/features/product/live_product_detail_screen.dart')
        .readAsStringSync();
    final cart = File('lib/features/cart/cart_screen.dart').readAsStringSync();

    expect(models, contains('class CatalogProductAvailability'));
    expect(models, contains('class CatalogPricingQuote'));
    expect(
      repository,
      contains("'/api/v1/customer/branches/\$branchId/pricing/quote'"),
    );
    expect(repository, contains("'product_id': productId"));
    expect(repository, isNot(contains("'unit_price':")));
    expect(configuration, contains('bool get complete'));
    expect(configuration, contains('CatalogVariant? get resolvedVariant'));
    expect(screen, contains('loadAvailability(widget.branchId, product.id)'));
    expect(screen, contains('unitPrice: freshQuote.unitTotal'));
    expect(screen, contains('CustomerCatalogStore.instance.quoteProduct'));
    expect(screen, isNot(contains("'+ EGP")));
    expect(screen, isNot(contains("'Vanilla'")));
    expect(screen, isNot(contains("'Oat Milk'")));
    expect(cart, contains('catalog.loadProduct(branchId, productId)'));
    expect(cart, contains('if (!CustomerCatalogStore.instance.usesApi)'));
  });
}
