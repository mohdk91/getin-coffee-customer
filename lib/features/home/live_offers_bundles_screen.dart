import 'package:flutter/material.dart';

import '../../core/catalog/customer_catalog_models.dart';
import '../../core/catalog/customer_catalog_store.dart';
import '../../core/content/mobile_app_content_models.dart';
import '../../core/content/mobile_app_content_store.dart';
import '../../core/theme/app_colors.dart';
import '../product/product_detail_screen.dart';
import 'live_offer_collection_resolver.dart';

class LiveOffersBundlesScreen extends StatelessWidget {
  final int branchId;
  final String branchName;
  final String serviceType;

  const LiveOffersBundlesScreen({
    super.key,
    required this.branchId,
    required this.branchName,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        MobileAppContentStore.instance,
        CustomerCatalogStore.instance,
      ]),
      builder: (context, _) {
        final products = CustomerCatalogStore.instance.productsForBranch(
          branchId,
        );
        final byId = <int, CatalogProduct>{
          for (final product in products) product.id: product,
        };
        final resolvedCollections = resolveLiveOfferCollections(
          published: MobileAppContentStore.instance.menuCollections,
          products: products,
        );
        final collections = resolvedCollections
            .map(
              (collection) => MapEntry(
                collection,
                collection.productIds
                    .map((id) => byId[id])
                    .whereType<CatalogProduct>()
                    .toList(growable: false),
              ),
            )
            .where((entry) => entry.value.isNotEmpty)
            .toList(growable: false)
          ..sort(
            (a, b) => a.key.sortOrder.compareTo(b.key.sortOrder),
          );

        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.green,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 0,
            title: const Text(
              'Offers & Bundles',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: collections.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(22, 120, 22, 32),
                    children: const [
                      Icon(
                        Icons.local_offer_outlined,
                        color: AppColors.green,
                        size: 44,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Fresh offers are coming soon.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Explore the menu for today’s available drinks and food.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                    itemCount: collections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final entry = collections[index];
                      return _OfferCollectionCard(
                        collection: entry.key,
                        products: entry.value,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LiveOfferCollectionDetailScreen(
                              branchId: branchId,
                              branchName: branchName,
                              serviceType: serviceType,
                              collection: entry.key,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

class LiveOfferCollectionDetailScreen extends StatelessWidget {
  final int branchId;
  final String branchName;
  final String serviceType;
  final MobileMenuCollection collection;

  const LiveOfferCollectionDetailScreen({
    super.key,
    required this.branchId,
    required this.branchName,
    required this.serviceType,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CustomerCatalogStore.instance,
      builder: (context, _) {
        final byId = <int, CatalogProduct>{
          for (final product
              in CustomerCatalogStore.instance.productsForBranch(branchId))
            product.id: product,
        };
        final products = collection.productIds
            .map((id) => byId[id])
            .whereType<CatalogProduct>()
            .toList(growable: false);

        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.green,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 0,
            title: Text(
              collection.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
              children: [
                if (collection.subtitle?.trim().isNotEmpty == true) ...[
                  Text(
                    collection.subtitle!.trim(),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                for (var index = 0; index < products.length; index++) ...[
                  _OfferProductTile(
                    product: products[index],
                    onTap: () => _openProduct(context, products[index]),
                  ),
                  if (index != products.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _openProduct(BuildContext context, CatalogProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          name: product.name,
          description: product.shortDescription,
          image: product.imageUrl ?? '',
          price: product.displayPrice,
          branchName: branchName,
          serviceType: serviceType,
          branchId: branchId,
          catalogProduct: product,
        ),
      ),
    );
  }
}

class _OfferCollectionCard extends StatelessWidget {
  final MobileMenuCollection collection;
  final List<CatalogProduct> products;
  final VoidCallback onTap;

  const _OfferCollectionCard({
    required this.collection,
    required this.products,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final first = products.first;
    final lowest = products.reduce(
      (a, b) => a.price <= b.price ? a : b,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 124,
              height: 132,
              child: first.imageUrl?.isNotEmpty == true
                  ? Image.network(
                      first.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: AppColors.beige,
                        child: Icon(
                          Icons.local_cafe_rounded,
                          color: AppColors.green,
                        ),
                      ),
                    )
                  : const ColoredBox(
                      color: AppColors.beige,
                      child: Icon(
                        Icons.local_cafe_rounded,
                        color: AppColors.green,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.isFeatured ? 'FEATURED BUNDLE' : 'GETIN OFFER',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      collection.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (collection.subtitle?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        collection.subtitle!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'From ${lowest.displayPrice}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${products.length} items',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.green,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferProductTile extends StatelessWidget {
  final CatalogProduct product;
  final VoidCallback onTap;

  const _OfferProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: product.imageUrl?.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: AppColors.beige,
                          ),
                        ),
                      )
                    : const ColoredBox(color: AppColors.beige),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.displayPrice,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
