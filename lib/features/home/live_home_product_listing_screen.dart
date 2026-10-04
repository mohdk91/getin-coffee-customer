import 'package:flutter/material.dart';

import '../../core/catalog/customer_catalog_models.dart';
import '../../core/membership/customer_membership_store.dart';
import '../../core/rewards/reward_earning_policy.dart';
import '../../core/theme/app_colors.dart';
import '../product/product_detail_screen.dart';

class LiveHomeProductListingScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<CatalogProduct> products;
  final int branchId;
  final String branchName;
  final String serviceType;

  const LiveHomeProductListingScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.products,
    required this.branchId,
    required this.branchName,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CustomerMembershipStore.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.green,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 360 ? 1 : 2;
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  if (subtitle?.trim().isNotEmpty == true)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          subtitle!.trim(),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          return _LiveProductCard(
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
                        childCount: products.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: columns == 1 ? 1.65 : 0.72,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LiveProductCard extends StatelessWidget {
  final CatalogProduct product;
  final VoidCallback onTap;

  const _LiveProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final membership = CustomerMembershipStore.instance;
    final earnedStars = RewardEarningPolicy.starsForPrice(
      product.displayPrice,
      isMember: membership.isActive,
      multiplier: membership.earningMultiplier,
    );

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox.expand(
                child: product.imageUrl?.trim().isNotEmpty == true
                    ? Image.network(
                        product.imageUrl!,
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.displayPrice,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.gold,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '+$earnedStars Stars${membership.hasBonusMultiplier ? ' · ${membership.earningMultiplierLabel}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 9.5,
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
    );
  }
}
