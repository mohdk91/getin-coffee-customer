import 'package:flutter/material.dart';

import '../../../core/auth/customer_auth_store.dart';
import '../../../core/catalog/customer_catalog_models.dart';
import '../../../core/catalog/customer_catalog_store.dart';
import '../../../core/content/mobile_app_content_models.dart';
import '../../../core/content/mobile_app_content_store.dart';
import '../../../core/membership/customer_membership_store.dart';
import '../../../core/rewards/customer_rewards_store.dart';
import '../../../core/rewards/reward_earning_policy.dart';
import '../../../core/rewards/customer_stamp_card_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../product/product_detail_screen.dart';
import '../live_home_product_listing_screen.dart';
import '../live_offer_collection_resolver.dart';
import '../live_offers_bundles_screen.dart';
import 'play_win_card.dart';
import 'rewards_progress_card.dart';

class ManagedProductSections extends StatelessWidget {
  final int branchId;
  final String branchName;
  final String serviceType;
  final VoidCallback onRewards;
  final VoidCallback onPlay;

  const ManagedProductSections({
    super.key,
    required this.branchId,
    required this.branchName,
    required this.serviceType,
    required this.onRewards,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        MobileAppContentStore.instance,
        CustomerCatalogStore.instance,
        CustomerRewardsStore.instance,
        CustomerStampCardStore.instance,
        CustomerMembershipStore.instance,
      ]),
      builder: (context, _) {
        final contentStore = MobileAppContentStore.instance;
        final configs = contentStore.homeSections.toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final products =
            CustomerCatalogStore.instance.productsForBranch(branchId);
        final collections = resolveLiveOfferCollections(
          published: MobileAppContentStore.instance.menuCollections,
          products: products,
        );

        if (configs.isEmpty && collections.isEmpty) {
          return const SizedBox.shrink();
        }

        final children = <Widget>[];
        var renderedOffers = false;

        void addSection(Widget child) {
          if (children.isNotEmpty) {
            children.add(const SizedBox(height: 22));
          }
          children.add(child);
        }

        for (final section in configs) {
          switch (section.source) {
            case 'rewards':
              addSection(
                RewardsProgressCard(
                  stars: CustomerRewardsStore.instance.stars,
                  targetStars: CustomerRewardsStore.instance.nextRewardTarget,
                  currentStamps: CustomerStampCardStore.instance.currentStamps,
                  memberActive: CustomerMembershipStore.instance.isActive,
                  onTap: onRewards,
                ),
              );
              break;
            case 'getin_play':
              addSection(PlayWinCard(onTap: onPlay));
              break;
            case 'offers':
              renderedOffers = true;
              if (collections.isNotEmpty && products.isNotEmpty) {
                addSection(
                  _ManagedCollectionGroup(
                    config: section,
                    collections: collections,
                    products: products,
                    branchId: branchId,
                    branchName: branchName,
                    serviceType: serviceType,
                  ),
                );
              }
              break;
            case 'featured_products':
            case 'catalog':
              if (products.isNotEmpty) {
                addSection(
                  _ManagedProductSection(
                    config: section,
                    products: _productsFor(section, products),
                    branchId: branchId,
                    branchName: branchName,
                    serviceType: serviceType,
                  ),
                );
              }
              break;
            case 'order_history':
              if (!CustomerAuthStore.instance.isAuthenticated &&
                  products.isNotEmpty) {
                addSection(
                  _ManagedProductSection(
                    config: section,
                    products: _orderAgainPreviewProducts(products),
                    branchId: branchId,
                    branchName: branchName,
                    serviceType: serviceType,
                  ),
                );
              }
              break;
          }
        }

        if (!renderedOffers && collections.isNotEmpty && products.isNotEmpty) {
          for (final collection in collections) {
            addSection(
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
            );
          }
        }

        if (children.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }

  List<CatalogProduct> _collectionProducts(
    MobileMenuCollection collection,
    List<CatalogProduct> products,
  ) {
    final byId = <int, CatalogProduct>{
      for (final product in products) product.id: product,
    };
    return collection.productIds
        .map((id) => byId[id])
        .whereType<CatalogProduct>()
        .toList(growable: false);
  }

  List<CatalogProduct> _orderAgainPreviewProducts(
    List<CatalogProduct> products,
  ) {
    if (products.length <= 4) return products;
    return products.skip(1).take(4).toList(growable: false);
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

class _ManagedCollectionGroup extends StatelessWidget {
  final MobileHomeSectionConfig config;
  final List<MobileMenuCollection> collections;
  final List<CatalogProduct> products;
  final int branchId;
  final String branchName;
  final String serviceType;

  const _ManagedCollectionGroup({
    required this.config,
    required this.collections,
    required this.products,
    required this.branchId,
    required this.branchName,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    final byId = <int, CatalogProduct>{
      for (final product in products) product.id: product,
    };
    final visibleCollections = collections
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
        .toList(growable: false);

    if (visibleCollections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          config: config,
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LiveOffersBundlesScreen(
                branchId: branchId,
                branchName: branchName,
                serviceType: serviceType,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: visibleCollections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = visibleCollections[index];
              return _OfferCollectionPreviewCard(
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
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final MobileHomeSectionConfig config;
  final VoidCallback? onSeeAll;

  const _SectionHeading({required this.config, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                config.title,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                ),
              ),
            ),
            if (onSeeAll != null)
              TextButton.icon(
                onPressed: onSeeAll,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: const Text('View all'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        if (config.subtitle?.isNotEmpty == true) ...[
          const SizedBox(height: 2),
          Text(
            config.subtitle!,
            style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
          ),
        ],
      ],
    );
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
        _SectionHeading(
          config: config,
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LiveHomeProductListingScreen(
                title: config.title,
                subtitle: config.subtitle,
                products: products,
                branchId: branchId,
                branchName: branchName,
                serviceType: serviceType,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 236,
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
                      image: _preferredProductImage(product) ?? '',
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
    final membership = CustomerMembershipStore.instance;
    final earnedStars = RewardEarningPolicy.starsForPrice(
      product.displayPrice,
      isMember: membership.isActive,
      multiplier: membership.earningMultiplier,
    );

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
                  child: _CatalogMedia(
                    url: _preferredProductImage(product),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.displayPrice,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '+$earnedStars Stars${membership.hasBonusMultiplier ? ' · ${membership.earningMultiplierLabel}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _OfferCollectionPreviewCard extends StatelessWidget {
  final MobileMenuCollection collection;
  final List<CatalogProduct> products;
  final VoidCallback onTap;

  const _OfferCollectionPreviewCard({
    required this.collection,
    required this.products,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lowest = products.reduce((a, b) => a.price <= b.price ? a : b);
    final imageUrl = _firstCollectionImage(products);

    return SizedBox(
      width: 210,
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 112,
                width: double.infinity,
                child: _CatalogMedia(url: imageUrl),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        collection.subtitle?.trim().isNotEmpty == true
                            ? collection.subtitle!.trim()
                            : '${products.length} available picks',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 9.5,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'From ${lowest.displayPrice}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 17,
                            color: AppColors.green,
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
      ),
    );
  }
}

String? _preferredProductImage(CatalogProduct product) {
  final primary = product.imageUrl?.trim();
  if (primary != null && primary.isNotEmpty) return primary;
  for (final url in product.gallery) {
    final candidate = url.trim();
    if (candidate.isNotEmpty) return candidate;
  }
  return null;
}

String? _firstCollectionImage(List<CatalogProduct> products) {
  for (final product in products) {
    final image = _preferredProductImage(product);
    if (image != null) return image;
  }
  return null;
}

class _CatalogMedia extends StatelessWidget {
  final String? url;

  const _CatalogMedia({this.url});

  @override
  Widget build(BuildContext context) {
    final value = url?.trim();
    if (value == null || value.isEmpty) return const _CatalogMediaFallback();

    return Image.network(
      value,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _CatalogMediaFallback();
      },
      errorBuilder: (_, __, ___) => const _CatalogMediaFallback(),
    );
  }
}

class _CatalogMediaFallback extends StatelessWidget {
  const _CatalogMediaFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.cream,
      child: Center(
        child: Icon(
          Icons.local_cafe_rounded,
          color: AppColors.green,
          size: 30,
        ),
      ),
    );
  }
}
