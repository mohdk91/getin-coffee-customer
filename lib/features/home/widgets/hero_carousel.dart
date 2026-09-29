import 'package:flutter/material.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/theme/app_colors.dart';

class HeroCarousel extends StatefulWidget {
  final VoidCallback onOrderNow;

  const HeroCarousel({
    super.key,
    required this.onOrderNow,
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _controller = PageController();
  int _index = 0;

  static const _images = [
    AppImages.hero1,
    AppImages.hero2,
    AppImages.hero3,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _images.length,
              onPageChanged: (value) {
                setState(() {
                  _index = value;
                });
              },
              itemBuilder: (_, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: AppColors.greenDark,
                        );
                      },
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xD90D211C),
                            Color(0x680D211C),
                            Color(0x090D211C),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const Positioned(
              left: 18,
              top: 18,
              right: 126,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FEATURED',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Good Coffee\nBrighter Days',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.04,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'More than coffee, a better day.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              bottom: 16,
              child: SizedBox(
                height: 34,
                child: FilledButton(
                  onPressed: widget.onOrderNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.beige,
                    foregroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Order Now',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                      ),
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
                children: List.generate(
                  _images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 3,
                    ),
                    width: i == _index ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.beige : Colors.white54,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
