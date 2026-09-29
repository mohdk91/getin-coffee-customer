import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class HomeOfferDetailScreen extends StatelessWidget {
  final String image;
  final String eyebrow;
  final String title;
  final String description;
  final String? price;
  final String? oldPrice;
  final String? badge;

  const HomeOfferDetailScreen({
    super.key,
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.price,
    this.oldPrice,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Offer Details',
          style: TextStyle(
            color: AppColors.green,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            6,
            compact ? 12 : 16,
            28,
          ),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: compact ? 1.45 : 1.75,
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.green,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.local_offer_outlined,
                      color: AppColors.beige,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              eyebrow,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 10,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: TextStyle(
                color: AppColors.green,
                fontSize: compact ? 26 : 29,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (price != null) ...[
              const SizedBox(height: 15),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Text(
                    price!,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (oldPrice != null)
                    Text(
                      oldPrice!,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.beige,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            const _OfferInfoCard(),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.green,
                    size: 19,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Demo offer details are local for now. Live availability, branch eligibility and final offer rules will come from the Laravel backend later.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.35,
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

class _OfferInfoCard extends StatelessWidget {
  const _OfferInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What’s included',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 13),
          _OfferInfoRow(
            icon: Icons.local_cafe_outlined,
            text: 'Choose one eligible coffee.',
          ),
          SizedBox(height: 10),
          _OfferInfoRow(
            icon: Icons.bakery_dining,
            text: 'Choose one eligible croissant or muffin.',
          ),
          SizedBox(height: 10),
          _OfferInfoRow(
            icon: Icons.storefront_outlined,
            text: 'Branch availability may vary.',
          ),
        ],
      ),
    );
  }
}

class _OfferInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _OfferInfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.green, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
