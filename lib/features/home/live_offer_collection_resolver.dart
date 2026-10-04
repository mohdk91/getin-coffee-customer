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

  if (visiblePublished.isNotEmpty) return visiblePublished;

  bool foodLike(CatalogProduct product) {
    final source =
        '${product.categoryName ?? ''} ${product.name}'.trim().toLowerCase();
    return source.contains('food') ||
        source.contains('bakery') ||
        source.contains('sandwich') ||
        source.contains('croissant') ||
        source.contains('muffin');
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
  if (drinks.isNotEmpty) {
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
  if (food.isNotEmpty) {
    fallback.add(
      MobileMenuCollection(
        id: -246902,
        slug: 'coffee-bite-pairings',
        title: 'Coffee & Bite Pairings',
        subtitle: 'Easy pairings for your next order.',
        isFeatured: true,
        sortOrder: 20,
        productIds: food,
      ),
    );
  }

  if (fallback.isEmpty) {
    return <MobileMenuCollection>[
      MobileMenuCollection(
        id: -246903,
        slug: 'getin-picks',
        title: 'GETIN Picks',
        subtitle: 'Popular choices available at this branch.',
        isFeatured: true,
        sortOrder: 10,
        productIds: products
            .take(6)
            .map((product) => product.id)
            .toList(growable: false),
      ),
    ];
  }

  return fallback;
}
