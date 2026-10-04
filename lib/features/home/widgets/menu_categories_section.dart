import 'package:flutter/material.dart';

import '../../../core/catalog/customer_catalog_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/home_mock_data.dart';

class MenuCategoriesSection extends StatelessWidget {
  final int branchId;

  const MenuCategoriesSection({
    super.key,
    required this.branchId,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CustomerCatalogStore.instance,
      builder: (context, _) {
        final store = CustomerCatalogStore.instance;
        final liveCategories = store.categoriesForBranch(branchId);

        // Production/staging must reflect the Control Panel catalog exactly.
        // Never replace an empty or failed API response with local demo data.
        if (store.usesApi) {
          if (liveCategories.isEmpty) {
            if (store.loading) {
              return const _CategoryLoadingState();
            }
            return const SizedBox.shrink();
          }

          final items = liveCategories
              .map(
                (category) => _CategoryTileData(
                  title: category.name,
                  image: category.imageUrl,
                  networkImage: true,
                ),
              )
              .toList(growable: false);

          return _CategoryStrip(items: items);
        }

        // Local mock categories remain available only for explicit development
        // mode where no API base URL is configured.
        final items = HomeMockData.categories
            .map(
              (category) => _CategoryTileData(
                title: category.title,
                image: category.image,
                networkImage: false,
              ),
            )
            .toList(growable: false);

        return _CategoryStrip(items: items);
      },
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<_CategoryTileData> items;

  const _CategoryStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(),
        const SizedBox(height: 10),
        SizedBox(
          height: 122,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];

              return SizedBox(
                width: 88,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 78,
                        height: 74,
                        color: AppColors.beige.withOpacity(0.42),
                        child: _CategoryImage(item: item),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.visible,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 10.5,
                          height: 1.05,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryImage extends StatelessWidget {
  final _CategoryTileData item;

  const _CategoryImage({required this.item});

  @override
  Widget build(BuildContext context) {
    final image = item.image?.trim() ?? '';
    if (image.isEmpty) {
      return const _CategoryFallbackIcon();
    }

    if (item.networkImage) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _CategoryFallbackIcon(),
      );
    }

    return Image.asset(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _CategoryFallbackIcon(),
    );
  }
}

class _CategoryFallbackIcon extends StatelessWidget {
  const _CategoryFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.local_cafe_rounded,
        color: AppColors.green,
        size: 28,
      ),
    );
  }
}

class _CategoryLoadingState extends StatelessWidget {
  const _CategoryLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(),
        const SizedBox(height: 10),
        SizedBox(
          height: 122,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) => SizedBox(
              width: 88,
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 74,
                    decoration: BoxDecoration(
                      color: AppColors.beige.withOpacity(0.42),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 54,
                    height: 8,
                    color: AppColors.beige.withOpacity(0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTileData {
  final String title;
  final String? image;
  final bool networkImage;

  const _CategoryTileData({
    required this.title,
    required this.image,
    required this.networkImage,
  });
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Explore Our Menu',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Text(
          'View All',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 2),
        Icon(
          Icons.chevron_right_rounded,
          color: AppColors.green,
          size: 18,
        ),
      ],
    );
  }
}
