import '../../core/catalog/customer_catalog_models.dart';
import '../../core/content/mobile_app_content_models.dart';

List<MobileMenuCollection> resolveLiveOfferCollections({
  required List<MobileMenuCollection> published,
  required List<CatalogProduct> products,
}) {
  if (products.isEmpty) return const <MobileMenuCollection>[];

  final productIds = products.map((product) => product.id).toSet();
  final visiblePublished = published
      .map(
        (collection) => MobileMenuCollection(
          id: collection.id,
          slug: collection.slug,
          title: collection.title,
          subtitle: collection.subtitle,
          isFeatured: collection.isFeatured,
          sortOrder: collection.sortOrder,
          productIds: collection.productIds
              .where(productIds.contains)
              .toList(growable: false),
        ),
      )
      .where((collection) => collection.productIds.isNotEmpty)
      .toList(growable: false)
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  // Keep Control Panel collections authoritative when at least two useful
  // collections resolve for the selected branch. If publishing is partial,
  // top up the section from the same live branch catalog so Offers & Bundles
  // never collapses into a single repetitive collection.
  if (visiblePublished.length >= 2) return visiblePublished;

  bool foodLike(CatalogProduct product) {
    final source =
        '${product.categoryName ?? ''} ${product.name}'.trim().toLowerCase();
    return source.contains('food') ||
        source.contains('bakery') ||
        source.contains('sandwich') ||
        source.contains('croissant') ||
        source.contains('muffin');
  }

  bool collectionLooksCoffee(MobileMenuCollection collection) {
    final source = '${collection.slug} ${collection.title}'.toLowerCase();
    return source.contains('coffee');
  }

  bool collectionLooksFood(MobileMenuCollection collection) {
    final source = '${collection.slug} ${collection.title}'.toLowerCase();
    return source.contains('breakfast') ||
        source.contains('bite') ||
        source.contains('bakery') ||
        source.contains('food') ||
        source.contains('bundle');
  }

  final drinks = products
      .where((product) => !foodLike(product))
      .take(5)
      .map((product) => product.id)
      .toList(growable: false);
  final food = products
      .where(foodLike)
      .take(5)
      .map((product) => product.id)
      .toList(growable: false);

  final fallback = <MobileMenuCollection>[];
  final hasCoffeeCollection = visiblePublished.any(collectionLooksCoffee);
  final hasFoodCollection = visiblePublished.any(collectionLooksFood);

  if (drinks.isNotEmpty && !hasCoffeeCollection) {
    fallback.add(
      MobileMenuCollection(
        id: -246901,
        slug: 'coffee-favorites',
        title: 'Coffee Favorites',
        subtitle: 'Customer favorites from this branch.',
        isFeatured: true,
        sortOrder: 10,
        productIds: drinks,
      ),
    );
  }

  if (!hasFoodCollection) {
    final pairingIds = <int>{
      if (drinks.isNotEmpty) drinks.first,
      ...food,
    }.take(5).toList(growable: false);

    if (pairingIds.isNotEmpty) {
      fallback.add(
        MobileMenuCollection(
          id: -246902,
          slug: 'coffee-bite-pairings',
          title: 'Coffee & Bite Pairings',
          subtitle: 'Coffee and bakery picks for your next order.',
          isFeatured: true,
          sortOrder: 20,
          productIds: pairingIds,
        ),
      );
    }
  }

  final merged = <MobileMenuCollection>[...visiblePublished, ...fallback]
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  if (merged.length >= 2) return merged;

  if (merged.isEmpty) {
    return <MobileMenuCollection>[
      MobileMenuCollection(
        id: -246903,
        slug: 'getin-picks',
        title: 'GETIN Picks',
        subtitle: 'Popular choices available at this branch.',
        isFeatured: true,
        sortOrder: 30,
        productIds: products
            .take(6)
            .map((product) => product.id)
            .toList(growable: false),
      ),
    ];
  }

  final usedIds = merged.expand((collection) => collection.productIds).toSet();
  var pickIds = products
      .where((product) => !usedIds.contains(product.id))
      .take(6)
      .map((product) => product.id)
      .toList(growable: false);

  if (pickIds.isEmpty) {
    pickIds =
        products.take(6).map((product) => product.id).toList(growable: false);
  }

  return <MobileMenuCollection>[
    ...merged,
    MobileMenuCollection(
      id: -246903,
      slug: 'getin-picks',
      title: 'GETIN Picks',
      subtitle: 'Popular choices available at this branch.',
      isFeatured: true,
      sortOrder: 30,
      productIds: pickIds,
    ),
  ];
}
