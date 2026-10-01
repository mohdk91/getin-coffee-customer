import 'package:flutter/material.dart';

import '../../../core/catalog/customer_catalog_models.dart';
import '../../../core/catalog/customer_catalog_store.dart';
import '../../../core/content/mobile_app_content_models.dart';
import '../../../core/content/mobile_app_content_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../product/product_detail_screen.dart';

class ManagedProductSections extends StatelessWidget {
  final int branchId;
  final String branchName;
  final String serviceType;

  const ManagedProductSections({
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
        final configs = MobileAppContentStore.instance.homeSections
            .where((section) => const {'best_sellers', 'seasonal', 'popular'}.contains(section.key))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final collections = MobileAppContentStore.instance.menuCollections
            .where((collection) => collection.productIds.isNotEmpty)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final products = CustomerCatalogStore.instance.productsForBranch(branchId);
        if ((configs.isEmpty && collections.isEmpty) || products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final collection in collections) ...[
              _ManagedProductSection(
                config: MobileHomeSectionConfig(
                  id: collection.id,
                  key: 'collection:${collection.slug}',
                  title: collection.title,
                  subtitle: collection.subtitle,
                  source: 'menu_collection',
                  sortOrder: collection.sortOrder,
                ),
                products: _collectionProducts(collection, products),
                branchId: branchId,
                branchName: branchName,
                serviceType: serviceType,
              ),
              const SizedBox(height: 22),
            ],
            for (final section in configs) ...[
              _ManagedProductSection(
                config: section,
                products: _productsFor(section, products),
                branchId: branchId,
                branchName: branchName,
                serviceType: serviceType,
              ),
              const SizedBox(height: 22),
            ],
          ],
        );
      },
    );
  }

  List<CatalogProduct> _collectionProducts(
    MobileMenuCollection collection,
    List<CatalogProduct> products,
  ) {
    final byId = <int, CatalogProduct>{for (final product in products) product.id: product};
    return collection.productIds
        .map((id) => byId[id])
        .whereType<CatalogProduct>()
        .toList(growable: false);
  }

  List<CatalogProduct> _productsFor(
    MobileHomeSectionConfig config,
    List<CatalogProduct> products,
  ) {
    if (config.source == 'featured_products' || config.key == 'best_sellers') {
      final featured = products.where((product) => product.isFeatured).toList();
      return (featured.isNotEmpty ? featured : products).take(8).toList();
    }
    if (config.key == 'seasonal') {
      return products.skip(products.length > 4 ? 2 : 0).take(8).toList();
    }
    return products.take(8).toList();
  }
}

class _ManagedProductSection extends StatelessWidget {
  final MobileHomeSectionConfig config;
  final List<CatalogProduct> products;
  final int branchId;
  final String branchName;
  final String serviceType;

  const _ManagedProductSection({
    required this.config,
    required this.products,
    required this.branchId,
    required this.branchName,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(config.title, style: const TextStyle(color: AppColors.green, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.35)),
        if (config.subtitle?.isNotEmpty == true) ...[
          const SizedBox(height: 2),
          Text(config.subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
        ],
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final product = products[index];
              return _CatalogCard(
                product: product,
                onTap: () => Navigator.of(context).push(
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final CatalogProduct product;
  final VoidCallback onTap;

  const _CatalogCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.beige),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox.expand(
                  child: product.imageUrl?.isNotEmpty == true
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.cream))
                      : const ColoredBox(color: AppColors.cream),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.green, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(product.displayPrice, style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
