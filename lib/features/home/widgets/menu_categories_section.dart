import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/mock/home_mock_data.dart';

class MenuCategoriesSection extends StatelessWidget {
  const MenuCategoriesSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const items = HomeMockData.categories;

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
                        child: Image.asset(
                          item.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.local_cafe_rounded,
                              color: AppColors.green,
                              size: 28,
                            );
                          },
                        ),
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
