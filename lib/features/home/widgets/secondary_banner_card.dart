import 'package:flutter/material.dart';

import '../../../core/content/mobile_app_content_models.dart';
import '../../../core/content/mobile_app_content_store.dart';
import '../../../core/theme/app_colors.dart';

class SecondaryBannerCard extends StatefulWidget {
  final ValueChanged<MobileContentDestination>? onDestination;

  const SecondaryBannerCard({super.key, this.onDestination});

  @override
  State<SecondaryBannerCard> createState() => _SecondaryBannerCardState();
}

class _SecondaryBannerCardState extends State<SecondaryBannerCard> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: MobileAppContentStore.instance,
      builder: (context, _) {
        final banners = MobileAppContentStore.instance.secondaryBanners;
        if (banners.isEmpty) return const SizedBox.shrink();

        final safeIndex = _index.clamp(0, banners.length - 1).toInt();
        if (safeIndex != _index) {
          _index = safeIndex;
        }

        return Column(
          children: [
            SizedBox(
              height: 136,
              child: PageView.builder(
                controller: _controller,
                itemCount: banners.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (_, index) => _BannerPage(
                  banner: banners[index],
                  onDestination: widget.onDestination,
                ),
              ),
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  banners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == safeIndex ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == safeIndex
                          ? AppColors.green
                          : AppColors.beige,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BannerPage extends StatelessWidget {
  final MobileBannerContent banner;
  final ValueChanged<MobileContentDestination>? onDestination;

  const _BannerPage({
    required this.banner,
    required this.onDestination,
  });

  @override
  Widget build(BuildContext context) {
    final image = banner.mobileImageUrl ?? banner.imageUrl;

    return InkWell(
      onTap: banner.destination.type == 'none' || onDestination == null
          ? null
          : () => onDestination!(banner.destination),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.beige),
          borderRadius: BorderRadius.circular(18),
          image: image != null && image.isNotEmpty
              ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
              : null,
          color: AppColors.greenDark,
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xE60D211C),
                Color(0x7A0D211C),
                Color(0x180D211C),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (banner.title?.isNotEmpty == true)
                Text(
                  banner.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (banner.text?.isNotEmpty == true) ...[
                const SizedBox(height: 5),
                Text(
                  banner.text!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
              if (banner.ctaLabel?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(
                  banner.ctaLabel!,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
