import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/membership/customer_membership_store.dart';

class RewardsProgressCard extends StatelessWidget {
  final int stars;
  final int targetStars;
  final int currentStamps;
  final bool memberActive;
  final VoidCallback onTap;

  const RewardsProgressCard({
    super.key,
    required this.stars,
    required this.targetStars,
    required this.currentStamps,
    required this.memberActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeTarget = targetStars <= 0 ? 1 : targetStars;
    final progress = (stars / safeTarget).clamp(0.0, 1.0);
    final remaining = targetStars - stars > 0 ? targetStars - stars : 0;

    return Material(
      color: AppColors.green,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            14,
            14,
            14,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.beige,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.green,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Getin Rewards',
                      style: TextStyle(
                        color: AppColors.beige,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$stars stars collected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: Colors.white.withOpacity(0.16),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.gold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      CustomerMembershipStore.instance.hasBonusMultiplier
                          ? '${CustomerMembershipStore.instance.earningMultiplierLabel} tier earning active'
                          : (remaining == 0
                              ? 'Your reward is ready'
                              : '$remaining stars until your next reward'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.76),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 58,
                color: Colors.white.withOpacity(0.14),
              ),
              const SizedBox(width: 11),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STAMP CARD',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$currentStamps / 7 stamps',
                      style: const TextStyle(
                        color: AppColors.beige,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Row(
                      children: [
                        Text(
                          'Free drink at 7',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9.5,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white70,
                          size: 15,
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
