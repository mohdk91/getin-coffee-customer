import 'package:flutter/material.dart';

import '../../core/favorites/customer_favorites_store.dart';
import '../../core/membership/customer_membership_store.dart';
import '../../core/navigation/app_navigation_controller.dart';
import '../../core/rewards/reward_earning_policy.dart';
import '../../core/theme/app_colors.dart';
import '../product/product_detail_screen.dart';
import 'home_offer_detail_screen.dart';

class HomeSectionProduct {
  final String name;
  final String subtitle;
  final String price;
  final String image;
  final String? badge;

  const HomeSectionProduct({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.image,
    this.badge,
  });
}

class HomeProductListingScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<HomeSectionProduct> products;
  final String branchName;
  final String serviceType;

  const HomeProductListingScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.products,
    required this.branchName,
    required this.serviceType,
  });

  void _openProduct(BuildContext context, HomeSectionProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          name: product.name,
          description: product.subtitle,
          image: product.image,
          price: product.price,
          branchName: branchName,
          serviceType: serviceType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            final width = constraints.maxWidth;
            final columns = width < 330 ? 1 : 2;
            final horizontalPadding = width < 380 ? 12.0 : 16.0;
            final spacing = width < 380 ? 10.0 : 12.0;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    4,
                    horizontalPadding,
                    12,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    4,
                    horizontalPadding,
                    24,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return _ListingProductCard(
                          product: product,
                          branchName: branchName,
                          serviceType: serviceType,
                          onTap: () => _openProduct(context, product),
                        );
                      },
                      childCount: products.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: columns == 1 ? 1.72 : 0.72,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class HomeOffersListingScreen extends StatelessWidget {
  const HomeOffersListingScreen({super.key});

  static const _offers = <_HomeOffer>[
    _HomeOffer(
      image: 'assets/images/home/sections/offer_breakfast_bundle.png',
      eyebrow: 'SPECIAL OFFER',
      title: 'Breakfast Bundle',
      description: 'Any coffee + croissant or muffin',
      price: 'EGP 99',
      oldPrice: 'EGP 125',
      badge: 'SAVE 20%',
    ),
    _HomeOffer(
      image: 'assets/images/home/sections/offer_rewards_free_drink.png',
      eyebrow: 'MEMBER EXCLUSIVE',
      title: 'Free Drink on 150 Stars',
      description: 'Turn your stars into great coffee.',
      membershipExclusive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.green,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
          itemCount: _offers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final offer = _offers[index];
            return _ListingOfferCard(
              offer: offer,
              onTap: () {
                if (offer.membershipExclusive) {
                  AppNavigationController.instance.openMembership();
                  Navigator.of(context).pop();
                  return;
                }

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HomeOfferDetailScreen(
                      image: offer.image,
                      eyebrow: offer.eyebrow,
                      title: offer.title,
                      description: offer.description,
                      price: offer.price,
                      oldPrice: offer.oldPrice,
                      badge: offer.badge,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ListingProductCard extends StatelessWidget {
  final HomeSectionProduct product;
  final String branchName;
  final String serviceType;
  final VoidCallback onTap;

  const _ListingProductCard({
    required this.product,
    required this.branchName,
    required this.serviceType,
    required this.onTap,
  });

  FavoriteProductEntry get _favoriteProduct => FavoriteProductEntry.fromProduct(
        name: product.name,
        description: product.subtitle,
        image: product.image,
        price: product.price,
        branchName: branchName,
        serviceType: serviceType,
      );

  @override
  Widget build(BuildContext context) {
    final earnedStars = RewardEarningPolicy.starsForPrice(
      product.price,
      isMember: CustomerMembershipStore.instance.isActive,
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
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.beige.withOpacity(0.35),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.local_cafe_rounded,
                        color: AppColors.green,
                        size: 36,
                      ),
                    ),
                  ),
                  if (product.badge != null)
                    Positioned(
                      left: 9,
                      top: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.beige.withOpacity(0.8),
                          ),
                        ),
                        child: Text(
                          product.badge!,
                          style: const TextStyle(
                            color: AppColors.beige,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.35,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 9,
                    top: 9,
                    child: AnimatedBuilder(
                      animation: CustomerFavoritesStore.instance,
                      builder: (context, _) {
                        final favorite = CustomerFavoritesStore.instance
                            .containsName(product.name);
                        return Material(
                          color: Colors.white.withOpacity(0.94),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => CustomerFavoritesStore.instance
                                .toggle(_favoriteProduct),
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                favorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: AppColors.green,
                                size: 18,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 13,
                        height: 1.08,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFD2A64A),
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '+$earnedStars Stars${CustomerMembershipStore.instance.isActive ? ' · 1.5×' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 8.7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.price,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.beige,
                            size: 19,
                          ),
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

class _ListingOfferCard extends StatelessWidget {
  final _HomeOffer offer;
  final VoidCallback onTap;

  const _ListingOfferCard({
    required this.offer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: MediaQuery.sizeOf(context).width < 380 ? 1.55 : 1.9,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                offer.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.green,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xF20D211C),
                      Color(0xB80D211C),
                      Color(0x220D211C),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      offer.eyebrow,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 9,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      offer.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      offer.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                    if (offer.price != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            offer.price!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (offer.oldPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              offer.oldPrice!,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (offer.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.beige,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              offer.badge!,
                              style: const TextStyle(
                                color: AppColors.green,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                offer.membershipExclusive
                                    ? 'Membership'
                                    : 'View Offer',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ],
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

class _HomeOffer {
  final String image;
  final String eyebrow;
  final String title;
  final String description;
  final String? price;
  final String? oldPrice;
  final String? badge;
  final bool membershipExclusive;

  const _HomeOffer({
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.price,
    this.oldPrice,
    this.badge,
    this.membershipExclusive = false,
  });
}
