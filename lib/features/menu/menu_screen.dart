import 'package:flutter/material.dart';

import '../../core/favorites/customer_favorites_store.dart';
import '../../core/catalog/customer_catalog_models.dart';
import '../../core/catalog/customer_catalog_store.dart';
import '../../core/membership/customer_membership_store.dart';
import '../../core/rewards/reward_earning_policy.dart';
import '../../core/products/product_type.dart';
import '../../core/theme/app_colors.dart';
import '../location/models/branch.dart';
import '../product/product_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  final Branch branch;
  final String serviceType;
  final Future<void> Function() onChangeBranch;

  const MenuScreen({
    super.key,
    required this.branch,
    required this.serviceType,
    required this.onChangeBranch,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _productScrollController = ScrollController();

  String _selectedCategory = 'All';
  String _query = '';

  List<_MenuCategory> get _categories => <_MenuCategory>[
        const _MenuCategory(
          title: 'All',
          icon: Icons.local_fire_department_rounded,
          image: 'assets/images/getin_logo_mark.png',
          tag: 'TOP',
        ),
        ...CustomerCatalogStore.instance.categoriesForBranch(widget.branch.id).map(
          (category) => _MenuCategory(
            title: category.name,
            icon: Icons.local_cafe_rounded,
            image: category.imageUrl ?? 'assets/images/getin_logo_mark.png',
          ),
        ),
      ];

  List<_MenuProduct> get _products => CustomerCatalogStore.instance
      .productsForBranch(widget.branch.id)
      .map(
        (product) => _MenuProduct(
          catalogProduct: product,
          id: product.id,
          name: product.name,
          description: product.shortDescription,
          price: product.displayPrice,
          category: product.categoryName ?? 'Other',
          image: product.imageUrl ?? 'assets/images/getin_logo_mark.png',
          branchIds: <int>[widget.branch.id],
          badge: product.isFeatured ? 'FEATURED' : null,
          productTypeCode: product.productType,
        ),
      )
      .toList(growable: false);

  @override
  void dispose() {
    _searchController.dispose();
    _productScrollController.dispose();
    super.dispose();
  }

  List<_MenuProduct> get _branchProducts {
    return _products
        .where((product) => product.branchIds.contains(widget.branch.id))
        .toList();
  }

  List<_MenuProduct> get _filteredProducts {
    final normalizedQuery = _query.trim().toLowerCase();

    return _branchProducts.where((product) {
      final categoryMatches =
          _selectedCategory == 'All' || product.category == _selectedCategory;
      final queryMatches = normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.description.toLowerCase().contains(normalizedQuery) ||
          product.category.toLowerCase().contains(normalizedQuery);

      return categoryMatches && queryMatches;
    }).toList();
  }

  int _categoryCount(String category) {
    final products = _branchProducts;
    if (category == 'All') return products.length;
    return products.where((product) => product.category == category).length;
  }

  void _openProduct(_MenuProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          name: product.name,
          description: product.description,
          image: product.image,
          price: product.price,
          branchName: widget.branch.name,
          serviceType: widget.serviceType,
          branchId: widget.branch.id,
          catalogProduct: product.catalogProduct,
          productType: product.type,
          productBadge: product.badge,
        ),
      ),
    );
  }

  void _selectCategory(String category) {
    if (_selectedCategory == category) return;

    setState(() => _selectedCategory = category);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_productScrollController.hasClients) return;

      _productScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final width = MediaQuery.sizeOf(context).width;
    final railWidth = width < 360
        ? 82.0
        : width < 420
            ? 88.0
            : 94.0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _MenuHeader(
              branch: widget.branch,
              serviceType: widget.serviceType,
              controller: _searchController,
              onBranchTap: widget.onChangeBranch,
              queryChanged: (value) {
                setState(() => _query = value);
              },
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: railWidth,
                    child: _CategoryRail(
                      categories: _categories,
                      selected: _selectedCategory,
                      countFor: _categoryCount,
                      onSelected: _selectCategory,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _MenuContentHeader(
                            category: _selectedCategory,
                            branchName: widget.branch.name,
                            productCount: products.length,
                            query: _query,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: products.isEmpty
                                ? const _EmptyMenuState()
                                : ListView.separated(
                                    controller: _productScrollController,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      12,
                                      8,
                                      88,
                                    ),
                                    itemCount: products.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      return _ReferenceProductCard(
                                        product: product,
                                        branchName: widget.branch.name,
                                        serviceType: widget.serviceType,
                                        onTap: () => _openProduct(product),
                                      );
                                    },
                                  ),
                          ),
                        ],
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

class _MenuHeader extends StatelessWidget {
  final Branch branch;
  final String serviceType;
  final TextEditingController controller;
  final VoidCallback onBranchTap;
  final ValueChanged<String> queryChanged;

  const _MenuHeader({
    required this.branch,
    required this.serviceType,
    required this.controller,
    required this.onBranchTap,
    required this.queryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final modeLabel = serviceType == 'pickup' ? 'Pickup' : 'Delivery';
    final shortBranch = branch.name.replaceFirst('Getin ', '');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: AppColors.beige,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  modeLabel,
                  style: const TextStyle(
                    color: AppColors.beige,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Material(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onBranchTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.beige,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Browsing menu for',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            shortBranch,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.beige,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Change',
                      style: TextStyle(
                        color: AppColors.beige,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.beige,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: queryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search this branch menu...',
              hintStyle: const TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.green,
                size: 21,
              ),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        controller.clear();
                        queryChanged('');
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.green,
                        size: 20,
                      ),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  final List<_MenuCategory> categories;
  final String selected;
  final int Function(String category) countFor;
  final ValueChanged<String> onSelected;

  const _CategoryRail({
    required this.categories,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0EEE8),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final active = selected == category.title;
          final count = countFor(category.title);

          return _CategoryRailTile(
            category: category,
            selected: active,
            count: count,
            onTap: () => onSelected(category.title),
          );
        },
      ),
    );
  }
}

class _CategoryRailTile extends StatelessWidget {
  final _MenuCategory category;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  const _CategoryRailTile({
    required this.category,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unavailable = category.title != 'All' && count == 0;

    return Material(
      color: selected ? const Color(0xFFE9E3D5) : Colors.transparent,
      child: InkWell(
        onTap: unavailable ? null : onTap,
        child: Opacity(
          opacity: unavailable ? 0.48 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? AppColors.green : Colors.transparent,
                  width: 4,
                ),
                bottom: const BorderSide(
                  color: AppColors.border,
                  width: 0.7,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(5, 8, 5, 7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (category.tag != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.beige
                          : AppColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      category.tag!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 6.4,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: _CatalogImage(
                    path: category.image,
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      category.icon,
                      color: selected ? AppColors.green : AppColors.muted,
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? AppColors.green : const Color(0xFF5C625F),
                    fontSize: 8.8,
                    height: 1.06,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  unavailable ? 'Unavailable' : '$count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.green : AppColors.muted,
                    fontSize: unavailable ? 6.1 : 7.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuContentHeader extends StatelessWidget {
  final String category;
  final String branchName;
  final int productCount;
  final String query;

  const _MenuContentHeader({
    required this.category,
    required this.branchName,
    required this.productCount,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final shortBranch = branchName.replaceFirst('Getin ', '');
    final hasQuery = query.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 13, 10, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasQuery ? 'Search results' : category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hasQuery
                ? '$productCount match${productCount == 1 ? '' : 'es'} in $category'
                : '$productCount item${productCount == 1 ? '' : 's'} at $shortBranch',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceProductCard extends StatelessWidget {
  final _MenuProduct product;
  final String branchName;
  final String serviceType;
  final VoidCallback onTap;

  const _ReferenceProductCard({
    required this.product,
    required this.branchName,
    required this.serviceType,
    required this.onTap,
  });

  FavoriteProductEntry get _favoriteProduct => FavoriteProductEntry.fromProduct(
        serverProductId: product.id,
        name: product.name,
        description: product.description,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final veryCompact = constraints.maxWidth < 230;
        final imageSize = veryCompact ? 64.0 : 74.0;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _CatalogImage(
                            path: product.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Container(
                                color: AppColors.beige.withOpacity(0.45),
                                child: const Icon(
                                  Icons.local_cafe_rounded,
                                  color: AppColors.green,
                                ),
                              );
                            },
                          ),
                          if (product.badge != null)
                            Positioned(
                              left: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withOpacity(0.94),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  product.badge!,
                                  style: const TextStyle(
                                    color: AppColors.beige,
                                    fontSize: 6.2,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: imageSize,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.green,
                                    fontSize: veryCompact ? 10.8 : 12.0,
                                    height: 1.06,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              AnimatedBuilder(
                                animation: CustomerFavoritesStore.instance,
                                builder: (context, _) {
                                  final favorite = CustomerFavoritesStore
                                      .instance
                                      .containsName(product.name);
                                  return InkResponse(
                                    onTap: () => CustomerFavoritesStore.instance
                                        .toggle(_favoriteProduct),
                                    radius: 18,
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Icon(
                                        favorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: favorite
                                            ? AppColors.green
                                            : AppColors.muted,
                                        size: veryCompact ? 17 : 18,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: Text(
                              product.description,
                              maxLines: veryCompact ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: veryCompact ? 8.2 : 8.9,
                                height: 1.15,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      product.price,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.green,
                                        fontSize: veryCompact ? 9.8 : 10.8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '★ +$earnedStars Stars${CustomerMembershipStore.instance.isActive ? ' · 1.5×' : ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFFD2A64A),
                                        fontSize: veryCompact ? 7.0 : 7.6,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: AppColors.green,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: onTap,
                                  customBorder: const CircleBorder(),
                                  child: SizedBox(
                                    width: veryCompact ? 28 : 30,
                                    height: veryCompact ? 28 : 30,
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: AppColors.beige,
                                      size: 19,
                                    ),
                                  ),
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
          ),
        );
      },
    );
  }
}

class _CatalogImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;

  const _CatalogImage({
    required this.path,
    required this.fit,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}

class _EmptyMenuState extends StatelessWidget {
  const _EmptyMenuState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: AppColors.muted,
              size: 34,
            ),
            SizedBox(height: 9),
            Text(
              'No items here',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try another category, search term, or branch.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCategory {
  final String title;
  final IconData icon;
  final String image;
  final String? tag;

  const _MenuCategory({
    required this.title,
    required this.icon,
    required this.image,
    this.tag,
  });
}

class _MenuProduct {
  final CatalogProduct catalogProduct;
  final int id;
  final String name;
  final String description;
  final String price;
  final String category;
  final String image;
  final String? badge;
  final List<int> branchIds;
  final String? productTypeCode;

  ProductType get type => GetinProductCatalog.typeFromCategory(
        productTypeCode ?? category,
      );

  const _MenuProduct({
    required this.catalogProduct,
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.image,
    required this.branchIds,
    this.badge,
    this.productTypeCode,
  });
}
