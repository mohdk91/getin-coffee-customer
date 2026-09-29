import 'package:flutter/material.dart';

import '../../../core/favorites/customer_favorites_store.dart';
import '../../../core/membership/customer_membership_store.dart';
import '../../../core/navigation/app_navigation_controller.dart';
import '../../../core/rewards/reward_earning_policy.dart';
import '../../../core/theme/app_colors.dart';
import '../../product/product_detail_screen.dart';
import '../home_offer_detail_screen.dart';
import '../home_section_listing_screen.dart';

class ProductSections extends StatelessWidget {
  final String branchName;
  final String serviceType;

  const ProductSections({
    super.key,
    required this.branchName,
    required this.serviceType,
  });

  static const _bestSellers = <HomeSectionProduct>[
    HomeSectionProduct(
      name: 'Iced Latte',
      subtitle: 'Classic & bold',
      price: 'EGP 65',
      image: 'assets/images/home/sections/iced_latte.png',
    ),
    HomeSectionProduct(
      name: 'Pistachio Dream Latte',
      subtitle: 'Rich & nutty',
      price: 'EGP 75',
      image: 'assets/images/home/sections/pistachio_latte.png',
    ),
    HomeSectionProduct(
      name: 'Turkey & Cheese',
      subtitle: 'Fresh & satisfying',
      price: 'EGP 85',
      image: 'assets/images/home/sections/turkey_sandwich.png',
    ),
    HomeSectionProduct(
      name: 'Berry Hibiscus',
      subtitle: 'Bright & refreshing',
      price: 'EGP 65',
      image: 'assets/images/home/sections/berry_hibiscus.png',
    ),
  ];

  static const _orderAgain = <HomeSectionProduct>[
    HomeSectionProduct(
      name: 'Iced Latte',
      subtitle: 'Classic & bold',
      price: 'EGP 65',
      image: 'assets/images/home/sections/iced_latte.png',
    ),
    HomeSectionProduct(
      name: 'Blueberry Muffin',
      subtitle: 'Soft & fruity',
      price: 'EGP 45',
      image: 'assets/images/home/sections/blueberry_muffin.png',
    ),
    HomeSectionProduct(
      name: 'Turkey & Cheese',
      subtitle: 'Fresh & satisfying',
      price: 'EGP 85',
      image: 'assets/images/home/sections/turkey_sandwich.png',
    ),
  ];

  static const _seasonal = <HomeSectionProduct>[
    HomeSectionProduct(
      name: 'Pistachio Dream Latte',
      subtitle: 'Rich & nutty',
      price: 'EGP 75',
      image: 'assets/images/home/sections/pistachio_latte.png',
      badge: 'NEW',
    ),
    HomeSectionProduct(
      name: 'Berry Hibiscus',
      subtitle: 'Bright & refreshing',
      price: 'EGP 65',
      image: 'assets/images/home/sections/berry_hibiscus.png',
      badge: 'LIMITED',
    ),
    HomeSectionProduct(
      name: 'Maple Croissant',
      subtitle: 'Buttery & rich',
      price: 'EGP 55',
      image: 'assets/images/home/sections/maple_croissant.png',
      badge: 'SEASONAL',
    ),
    HomeSectionProduct(
      name: 'Caramel Latte',
      subtitle: 'Sweet & smooth',
      price: 'EGP 70',
      image: 'assets/images/home/sections/caramel_latte.png',
      badge: 'NEW',
    ),
  ];

  static const _popular = <HomeSectionProduct>[
    HomeSectionProduct(
      name: 'Iced Latte',
      subtitle: 'Classic & bold',
      price: 'EGP 65',
      image: 'assets/images/home/sections/iced_latte.png',
    ),
    HomeSectionProduct(
      name: 'Turkey & Cheese',
      subtitle: 'Fresh & satisfying',
      price: 'EGP 85',
      image: 'assets/images/home/sections/turkey_sandwich.png',
    ),
    HomeSectionProduct(
      name: 'Blueberry Muffin',
      subtitle: 'Soft & fruity',
      price: 'EGP 45',
      image: 'assets/images/home/sections/blueberry_muffin.png',
    ),
    HomeSectionProduct(
      name: 'Pistachio Dream Latte',
      subtitle: 'Rich & nutty',
      price: 'EGP 75',
      image: 'assets/images/home/sections/pistachio_latte.png',
    ),
  ];

  void _openProductListing(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<HomeSectionProduct> products,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeProductListingScreen(
          title: title,
          subtitle: subtitle,
          products: products,
          branchName: branchName,
          serviceType: serviceType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortBranch = branchName.replaceFirst('Getin ', '');

    void openProduct(HomeSectionProduct product) {
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

    void openOffers() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HomeOffersListingScreen(),
        ),
      );
    }

    void openBreakfastBundle() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HomeOfferDetailScreen(
            image: 'assets/images/home/sections/offer_breakfast_bundle.png',
            eyebrow: 'SPECIAL OFFER',
            title: 'Breakfast Bundle',
            description: 'Any coffee + croissant or muffin',
            price: 'EGP 99',
            oldPrice: 'EGP 125',
            badge: 'SAVE 20%',
          ),
        ),
      );
    }

    void openMembership() {
      AppNavigationController.instance.openMembership();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Best Sellers',
          subtitle: 'Customer favorites right now.',
          onSeeAll: () => _openProductListing(
            context,
            title: 'Best Sellers',
            subtitle: 'Customer favorites right now.',
            products: _bestSellers,
          ),
        ),
        const SizedBox(height: 10),
        _ProductScroller(
          products: _bestSellers,
          cardWidth: 176,
          height: 222,
          branchName: branchName,
          serviceType: serviceType,
          onProductTap: openProduct,
        ),
        const SizedBox(height: 22),
        _SectionHeader(
          title: 'Order Again',
          subtitle: 'Your recent favorites, just a tap away.',
          onSeeAll: () => _openProductListing(
            context,
            title: 'Order Again',
            subtitle: 'Your recent favorites, just a tap away.',
            products: _orderAgain,
          ),
        ),
        const SizedBox(height: 10),
        _ProductScroller(
          products: _orderAgain,
          cardWidth: 158,
          height: 194,
          compact: true,
          branchName: branchName,
          serviceType: serviceType,
          onProductTap: openProduct,
        ),
        const SizedBox(height: 22),
        _SectionHeader(
          title: 'Offers & Bundles',
          subtitle: 'Great taste. Greater value.',
          onSeeAll: openOffers,
        ),
        const SizedBox(height: 10),
        _OffersScroller(
          onBreakfastBundleTap: openBreakfastBundle,
          onMembershipTap: openMembership,
        ),
        const SizedBox(height: 22),
        _SectionHeader(
          title: 'New & Seasonal',
          subtitle: 'Fresh flavors for every season.',
          onSeeAll: () => _openProductListing(
            context,
            title: 'New & Seasonal',
            subtitle: 'Fresh flavors for every season.',
            products: _seasonal,
          ),
        ),
        const SizedBox(height: 10),
        _ProductScroller(
          products: _seasonal,
          cardWidth: 176,
          height: 222,
          branchName: branchName,
          serviceType: serviceType,
          onProductTap: openProduct,
        ),
        const SizedBox(height: 22),
        _SectionHeader(
          title: 'Popular at Getin $shortBranch',
          subtitle: 'Popular choices at your selected branch.',
          onSeeAll: () => _openProductListing(
            context,
            title: 'Popular at Getin $shortBranch',
            subtitle: 'Popular choices at your selected branch.',
            products: _popular,
          ),
        ),
        const SizedBox(height: 10),
        _ProductScroller(
          products: _popular,
          cardWidth: 176,
          height: 222,
          branchName: branchName,
          serviceType: serviceType,
          onProductTap: openProduct,
        ),
        const SizedBox(height: 22),
        _FinalBanner(onTap: openMembership),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                softWrap: true,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'See all $title',
              child: InkWell(
                onTap: onSeeAll,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.green,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10.5,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ProductScroller extends StatelessWidget {
  final List<HomeSectionProduct> products;
  final double cardWidth;
  final double height;
  final bool compact;
  final String branchName;
  final String serviceType;
  final ValueChanged<HomeSectionProduct> onProductTap;

  const _ProductScroller({
    required this.products,
    required this.cardWidth,
    required this.height,
    required this.branchName,
    required this.serviceType,
    required this.onProductTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final narrow = screenWidth < 380;
    final extraForText = (textScale - 1.0).clamp(0.0, 0.5).toDouble() * 54;
    final resolvedHeight = height + extraForText + (narrow ? 8 : 0);
    final resolvedWidth = narrow ? (compact ? 152.0 : 164.0) : cardWidth;

    return SizedBox(
      height: resolvedHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => SizedBox(
          width: resolvedWidth,
          child: _ProductCard(
            product: products[index],
            compact: compact,
            branchName: branchName,
            serviceType: serviceType,
            onTap: () => onProductTap(products[index]),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final HomeSectionProduct product;
  final bool compact;
  final String branchName;
  final String serviceType;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.compact,
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
    final imageHeight = compact ? 88.0 : 108.0;
    final earnedStars = RewardEarningPolicy.starsForPrice(
      product.price,
      isMember: CustomerMembershipStore.instance.isActive,
    );

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight,
              width: double.infinity,
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
                        size: 32,
                      ),
                    ),
                  ),
                  if (product.badge != null)
                    Positioned(
                      left: 8,
                      top: 8,
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
                    right: 8,
                    top: 8,
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
                              width: 30,
                              height: 30,
                              child: Icon(
                                favorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: AppColors.green,
                                size: 17,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      softWrap: true,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 12.1,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.6,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 11.7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.beige,
                            size: 18,
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

class _OffersScroller extends StatelessWidget {
  final VoidCallback onBreakfastBundleTap;
  final VoidCallback onMembershipTap;

  const _OffersScroller({
    required this.onBreakfastBundleTap,
    required this.onMembershipTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).width < 380 ? 218 : 202,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            width: 250,
            child: _OfferCard(
              image: 'assets/images/home/sections/offer_breakfast_bundle.png',
              eyebrow: 'SPECIAL OFFER',
              title: 'Breakfast Bundle',
              description: 'Any coffee + croissant or muffin',
              price: 'EGP 99',
              oldPrice: 'EGP 125',
              buttonLabel: 'Order Now',
              showSaveBadge: true,
              onTap: onBreakfastBundleTap,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 196,
            child: _OfferCard(
              image: 'assets/images/home/sections/offer_rewards_free_drink.png',
              eyebrow: 'MEMBER EXCLUSIVE',
              title: 'Free Drink on 150 Stars',
              description: 'Turn your stars into great coffee.',
              buttonLabel: 'Learn More',
              onTap: onMembershipTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final String image;
  final String eyebrow;
  final String title;
  final String description;
  final String? price;
  final String? oldPrice;
  final String buttonLabel;
  final bool showSaveBadge;
  final VoidCallback onTap;

  const _OfferCard({
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
    this.price,
    this.oldPrice,
    this.showSaveBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              image,
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xEF0D211C),
                    Color(0xB80D211C),
                    Color(0x220D211C),
                  ],
                ),
              ),
            ),
            if (showSaveBadge)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.beige,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'SAVE\n20%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 9.5,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 8,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9.6,
                      height: 1.2,
                    ),
                  ),
                  if (price != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          price!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (oldPrice != null) ...[
                          const SizedBox(width: 7),
                          Text(
                            oldPrice!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    height: 31,
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.beige,
                        foregroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class _FinalBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _FinalBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;

    return AspectRatio(
      aspectRatio: compact ? 1.62 : 2.05,
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
                'assets/images/home/sections/final_membership_banner.png',
                fit: BoxFit.cover,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xF2132D26),
                      Color(0xB8132D26),
                      Color(0x11132D26),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GETIN MEMBERSHIP',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 8,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'More Stars.\nMore Good Days.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              height: 1.02,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Free drinks, exclusive offers, and more.',
                            maxLines: 2,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9.4,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: SizedBox(
                          height: 34,
                          child: FilledButton(
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.beige,
                              foregroundColor: AppColors.green,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: const Text(
                              'Join Now',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
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
