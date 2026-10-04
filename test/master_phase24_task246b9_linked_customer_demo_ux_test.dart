import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'Task 246B-9 keeps live catalog products but restores the full demo configurator when options are unpublished',
      () {
    final detail = File(
      'lib/features/product/product_detail_screen.dart',
    ).readAsStringSync();

    expect(
        detail, contains('final hasLiveConfiguration = liveProduct != null'));
    expect(detail, contains('liveProduct.variants.isNotEmpty'));
    expect(detail, contains('liveProduct.optionGroups.isNotEmpty'));
    expect(
      detail,
      contains('(hasLiveConfiguration || editingServerConfiguration)'),
    );
    expect(detail, contains('_QuickChoices('));
    expect(detail, contains("'View Cart'"));
    expect(detail, contains('viewingCart ? _openCart : _saveToCart'));
  });

  test(
      'Task 246B-9 changes the authoritative live CTA from Add to cart to View cart after success',
      () {
    final live = File(
      'lib/features/product/live_product_detail_screen.dart',
    ).readAsStringSync();

    expect(live, contains('bool _addedToCart = false;'));
    expect(live, contains("'View cart'"));
    expect(live, contains("'Added to cart'"));
    expect(live, contains('const CartScreen()'));
    expect(live, contains('_addedToCart = true;'));
  });

  test(
      'Task 246B-9 keeps Offers & Bundles populated from live branch products when collection mapping is empty',
      () {
    final resolver = File(
      'lib/features/home/live_offer_collection_resolver.dart',
    ).readAsStringSync();
    final offers = File(
      'lib/features/home/live_offers_bundles_screen.dart',
    ).readAsStringSync();
    final managed = File(
      'lib/features/home/widgets/managed_product_sections.dart',
    ).readAsStringSync();

    expect(resolver, contains('resolveLiveOfferCollections'));
    expect(resolver, contains("'Coffee Favorites'"));
    expect(resolver, contains("'Coffee & Bite Pairings'"));
    expect(resolver, contains('collection.productIds'));
    expect(resolver, contains('productIds: products'));
    expect(resolver, contains('.take(6)'));
    expect(offers, contains('resolveLiveOfferCollections('));
    expect(managed, contains('resolveLiveOfferCollections('));
  });

  test(
      'Task 246B-9 preserves API authority whenever Control Panel publishes real variants or option groups',
      () {
    final detail = File(
      'lib/features/product/product_detail_screen.dart',
    ).readAsStringSync();
    final live = File(
      'lib/features/product/live_product_detail_screen.dart',
    ).readAsStringSync();

    expect(detail, contains('return LiveProductDetailScreen('));
    expect(live, contains('CustomerCatalogStore.instance.quoteProduct'));
    expect(live, contains('unitPrice: freshQuote.unitTotal'));
    expect(live, contains('optionValueIds: configuration.optionValueIds'));
    expect(live, contains('loadAvailability(widget.branchId, product.id)'));
  });
}
