import 'package:flutter/material.dart';

import '../../../core/content/mobile_app_content_models.dart';
import '../../../core/content/mobile_app_content_store.dart';
import '../../../core/theme/app_colors.dart';

class SecondaryBannerCard extends StatelessWidget {
  final ValueChanged<MobileContentDestination>? onDestination;

  const SecondaryBannerCard({super.key, this.onDestination});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: MobileAppContentStore.instance,
      builder: (context, _) {
        final banners = MobileAppContentStore.instance.secondaryBanners;
        if (banners.isEmpty) return const SizedBox.shrink();
        final banner = banners.first;
        final image = banner.mobileImageUrl ?? banner.imageUrl;
        return InkWell(
          onTap: banner.destination.type == 'none' || onDestination == null
              ? null
              : () => onDestination!(banner.destination),
          child: Container(
            constraints: const BoxConstraints(minHeight: 116),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.beige),
              image: image != null && image.isNotEmpty
                  ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
                  : null,
              color: AppColors.greenDark,
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xE60D211C), Color(0x7A0D211C), Color(0x180D211C)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (banner.title?.isNotEmpty == true)
                    Text(banner.title!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  if (banner.text?.isNotEmpty == true) ...[
                    const SizedBox(height: 5),
                    Text(banner.text!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                  if (banner.ctaLabel?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    Text(banner.ctaLabel!, style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
