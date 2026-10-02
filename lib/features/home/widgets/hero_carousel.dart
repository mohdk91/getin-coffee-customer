import 'package:flutter/material.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/content/mobile_app_content_models.dart';
import '../../../core/content/mobile_app_content_store.dart';
import '../../../core/theme/app_colors.dart';

class HeroCarousel extends StatefulWidget {
  final int branchId;
  final String? marketCode;
  final String fulfillment;
  final VoidCallback onOrderNow;
  final ValueChanged<MobileContentDestination>? onDestination;

  const HeroCarousel({
    super.key,
    required this.branchId,
    required this.fulfillment,
    required this.onOrderNow,
    this.marketCode,
    this.onDestination,
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _controller = PageController();
  int _index = 0;
  static const _fallbackImages = [AppImages.hero1, AppImages.hero2, AppImages.hero3];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId ||
        oldWidget.marketCode != widget.marketCode ||
        oldWidget.fulfillment != widget.fulfillment) {
      _index = 0;
      _refresh();
    }
  }

  void _refresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MobileAppContentStore.instance.refresh(
        branchId: widget.branchId,
        market: widget.marketCode,
        fulfillment: widget.fulfillment,
      );
    });
  }

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
        final store = MobileAppContentStore.instance;
        final banners = store.heroBanners;
        if (banners.isEmpty && store.usesApi) {
          return const SizedBox.shrink();
        }
        final count = banners.isEmpty ? _fallbackImages.length : banners.length;
        final safeIndex = _index.clamp(0, count - 1).toInt();
        final active = banners.isEmpty ? null : banners[safeIndex];

        return AspectRatio(
          aspectRatio: 1.72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: count,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, index) {
                    final banner = banners.isEmpty ? null : banners[index];
                    final image = banner?.mobileImageUrl ?? banner?.imageUrl;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        image != null && image.isNotEmpty
                            ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.greenDark))
                            : Image.asset(_fallbackImages[index], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.greenDark)),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xD90D211C), Color(0x680D211C), Color(0x090D211C)],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  left: 18,
                  top: 18,
                  right: 126,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FEATURED', style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
                      const SizedBox(height: 7),
                      Text(active?.title?.trim().isNotEmpty == true ? active!.title! : 'Good Coffee\nBrighter Days', style: const TextStyle(color: Colors.white, fontSize: 24, height: 1.04, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      const SizedBox(height: 7),
                      Text(active?.text?.trim().isNotEmpty == true ? active!.text! : 'More than coffee, a better day.', style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                    ],
                  ),
                ),
                Positioned(
                  left: 18,
                  bottom: 16,
                  child: SizedBox(
                    height: 34,
                    child: FilledButton(
                      onPressed: () {
                        if (active != null && active.destination.type != 'none' && widget.onDestination != null) {
                          widget.onDestination!(active.destination);
                        } else {
                          widget.onOrderNow();
                        }
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.beige, foregroundColor: AppColors.green, padding: const EdgeInsets.symmetric(horizontal: 16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(active?.ctaLabel?.trim().isNotEmpty == true ? active!.ctaLabel! : 'Order Now', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 3),
                          const Icon(Icons.chevron_right_rounded, size: 17),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 13,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(count, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == safeIndex ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(color: i == safeIndex ? AppColors.beige : Colors.white54, borderRadius: BorderRadius.circular(99)),
                    )),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
