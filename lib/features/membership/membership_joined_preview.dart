import 'package:flutter/material.dart';

import '../../core/membership/customer_membership_store.dart';
import '../../core/rewards/customer_rewards_store.dart';
import '../../core/rewards/customer_stamp_card_store.dart';
import '../../core/theme/app_colors.dart';
import '../rewards/rewards_screen.dart';

class MembershipJoinedPreview extends StatelessWidget {
  final bool showBackButton;

  const MembershipJoinedPreview({
    super.key,
    required this.showBackButton,
  });

  @override
  Widget build(BuildContext context) {
    final membership = CustomerMembershipStore.instance;
    final rewards = CustomerRewardsStore.instance;
    final stamps = CustomerStampCardStore.instance;
    final stars = rewards.stars;
    const goldThreshold = 300;
    final progress = (stars / goldThreshold).clamp(0.0, 1.0).toDouble();
    final toGold = (goldThreshold - stars).clamp(0, goldThreshold).toInt();

    return AnimatedBuilder(
      animation: Listenable.merge([membership, rewards, stamps]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            automaticallyImplyLeading: showBackButton,
            backgroundColor: AppColors.cream,
            surfaceTintColor: AppColors.cream,
            foregroundColor: AppColors.green,
            elevation: 0,
            title: const Text(
              'GETIN Membership',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _MemberHero(
                stars: rewards.stars,
                multiplier: membership.earningMultiplierLabel,
                progress: progress,
                toGold: toGold,
              ),
              const SizedBox(height: 14),
              _MembershipStatusCard(
                billingCycle: membership.billingCycle,
              ),
              const SizedBox(height: 14),
              _RewardsAndStampCard(
                stars: rewards.stars,
                currentStamps: stamps.currentStamps,
                requiredStamps: stamps.requiredStamps,
                onOpenRewards: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RewardsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'YOUR BENEFITS',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 9),
              const _BenefitsGrid(),
              const SizedBox(height: 18),
              _TierJourneyCard(
                stars: rewards.stars,
                progress: progress,
                toGold: toGold,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MemberHero extends StatelessWidget {
  final int stars;
  final String multiplier;
  final double progress;
  final int toGold;

  const _MemberHero({
    required this.stars,
    required this.multiplier,
    required this.progress,
    required this.toGold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.gold,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Green Member',
            style: TextStyle(
              color: AppColors.beige,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$multiplier Stars on eligible orders',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'STARS',
                  value: '$stars',
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white24,
              ),
              const Expanded(
                child: _HeroMetric(
                  label: 'MEMBER PRICE',
                  value: 'Active',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Text(
                'Green',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                'Gold',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            toGold == 0 ? 'Gold unlocked' : '$toGold Stars to Gold',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.beige,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MembershipStatusCard extends StatelessWidget {
  final String billingCycle;

  const _MembershipStatusCard({required this.billingCycle});

  @override
  Widget build(BuildContext context) {
    final annual = billingCycle == 'annual';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Membership active',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  annual
                      ? 'Annual plan · EGP 1,239 / year'
                      : 'Monthly plan · EGP 129 / month',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.gold,
          ),
        ],
      ),
    );
  }
}

class _RewardsAndStampCard extends StatelessWidget {
  final int stars;
  final int currentStamps;
  final int requiredStamps;
  final VoidCallback onOpenRewards;

  const _RewardsAndStampCard({
    required this.stars,
    required this.currentStamps,
    required this.requiredStamps,
    required this.onOpenRewards,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onOpenRewards,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rewards',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$stars Stars available',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stamp Card',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$currentStamps / $requiredStamps collected',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitsGrid extends StatelessWidget {
  const _BenefitsGrid();

  @override
  Widget build(BuildContext context) {
    const benefits = <(IconData, String, String)>[
      (Icons.star_rounded, '1.5× Stars', 'Earn faster on eligible orders'),
      (Icons.sell_rounded, 'Member Prices', 'Special prices on selected items'),
      (
        Icons.card_giftcard_rounded,
        'Monthly Perks',
        'New benefits throughout the month'
      ),
      (Icons.cake_rounded, 'Birthday Treat', 'A little extra on your birthday'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: benefits.map((benefit) {
        return SizedBox(
          width: (MediaQuery.sizeOf(context).width - 42) / 2,
          child: Container(
            constraints: const BoxConstraints(minHeight: 122),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(benefit.$1, color: AppColors.green, size: 22),
                const SizedBox(height: 10),
                Text(
                  benefit.$2,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  benefit.$3,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _TierJourneyCard extends StatelessWidget {
  final int stars;
  final double progress;
  final int toGold;

  const _TierJourneyCard({
    required this.stars,
    required this.progress,
    required this.toGold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E8D4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your tier journey',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$stars lifetime Stars · ${toGold == 0 ? 'Gold unlocked' : '$toGold more to Gold'}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 13),
          const Row(
            children: [
              _TierPill(label: 'GREEN', active: true),
              SizedBox(width: 7),
              _TierPill(label: 'GOLD', active: false),
              SizedBox(width: 7),
              _TierPill(label: 'BLACK', active: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierPill extends StatelessWidget {
  final String label;
  final bool active;

  const _TierPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppColors.green : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? AppColors.green : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.beige : AppColors.muted,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
