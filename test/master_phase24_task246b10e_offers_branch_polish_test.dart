import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-10E keeps View all chevrons after the label', () {
    final managed = File(
      'lib/features/home/widgets/managed_product_sections.dart',
    ).readAsStringSync();
    final branches = File(
      'lib/features/home/widgets/nearest_branches_section.dart',
    ).readAsStringSync();

    expect(managed, contains('iconAlignment: IconAlignment.end'));
    expect(managed, contains("label: const Text('View all')"));
    expect(branches, contains('iconAlignment: IconAlignment.end'));
    expect(branches, contains("'View all'"));
  });

  test('Task 246B-10E renders Offers and Bundles as populated collection cards',
      () {
    final resolver = File(
      'lib/features/home/live_offer_collection_resolver.dart',
    ).readAsStringSync();
    final managed = File(
      'lib/features/home/widgets/managed_product_sections.dart',
    ).readAsStringSync();
    final offers = File(
      'lib/features/home/live_offers_bundles_screen.dart',
    ).readAsStringSync();

    expect(resolver, contains('if (visiblePublished.length >= 2)'));
    expect(resolver, contains('hasFoodCollection'));
    expect(resolver, contains("'Coffee & Bite Pairings'"));
    expect(managed, contains('class _OfferCollectionPreviewCard'));
    expect(managed, contains('LiveOfferCollectionDetailScreen('));
    expect(managed, contains('visibleCollections.length'));
    expect(offers, contains('resolveLiveOfferCollections('));
  });

  test('Task 246B-10E keeps branch cards equal and San Stefano on one line',
      () {
    final branches = File(
      'lib/features/home/widgets/nearest_branches_section.dart',
    ).readAsStringSync();

    expect(branches, contains('_branchDisplayName(item.branch.name)'));
    expect(branches, contains("RegExp(r'^getin\\s+', caseSensitive: false)"));
    expect(branches, contains('maxLines: 1'));
    expect(branches, contains('softWrap: false'));
    expect(branches, contains('overflow: TextOverflow.ellipsis'));
    expect(branches, contains('height: 17'));
  });

  test('Task 246B-10E gives product cards gallery and loading fallbacks', () {
    final managed = File(
      'lib/features/home/widgets/managed_product_sections.dart',
    ).readAsStringSync();
    final offers = File(
      'lib/features/home/live_offers_bundles_screen.dart',
    ).readAsStringSync();

    expect(managed, contains('for (final url in product.gallery)'));
    expect(managed, contains('loadingBuilder:'));
    expect(managed, contains('class _CatalogMediaFallback'));
    expect(offers, contains('for (final url in product.gallery)'));
    expect(offers, contains('loadingBuilder:'));
    expect(offers, contains('class _OfferMediaFallback'));
  });
}
