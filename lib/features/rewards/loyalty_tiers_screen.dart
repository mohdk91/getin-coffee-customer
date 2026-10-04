import 'package:flutter/material.dart';

import '../../core/membership/customer_membership_store.dart';
import '../../core/theme/app_colors.dart';

class LoyaltyTiersScreen extends StatelessWidget {
  const LoyaltyTiersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CustomerMembershipStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final current = store.currentTier;
        final next = store.nextTier;
        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            backgroundColor: AppColors.cream,
            surfaceTintColor: AppColors.cream,
            foregroundColor: AppColors.green,
            elevation: 0,
            title: const Text(
              'Loyalty Tiers',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: store.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR LOYALTY TIER',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        current?.name ?? 'Green',
                        style: const TextStyle(
                          color: AppColors.beige,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${store.loyaltyEarningMultiplierLabel} loyalty earning · ${store.lifetimePoints} lifetime Stars',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: store.progress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.gold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        next == null
                            ? 'Highest loyalty tier reached'
                            : '${store.pointsToNext} Stars to ${next.name}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'LOYALTY TIERS',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                if (store.tiers.isEmpty)
                  const _LoyaltyEmptyCard()
                else
                  ...store.tiers.map(
                    (tier) => _LoyaltyTierCard(
                      tier: tier,
                      current: current?.id == tier.id,
                    ),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Loyalty tier progress is based on eligible activity. GETIN Membership is a separate paid membership with its own benefits.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                    height: 1.4,
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

class _LoyaltyTierCard extends StatelessWidget {
  final CustomerMembershipTier tier;
  final bool current;

  const _LoyaltyTierCard({required this.tier, required this.current});

  @override
  Widget build(BuildContext context) {
    final benefits = tier.benefits.entries
        .where(
            (entry) => entry.value == true || entry.value.toString().isNotEmpty)
        .map((entry) => entry.key.replaceAll('_', ' '))
        .toList(growable: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: current ? AppColors.green : AppColors.border,
          width: current ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.name,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${tier.minimumLifetimePoints} lifetime Stars · ${tier.multiplierLabel} earning',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
                if (benefits.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    benefits.join(' · '),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (current)
            const Chip(
              label: Text('CURRENT'),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _LoyaltyEmptyCard extends StatelessWidget {
  const _LoyaltyEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Your loyalty tier will appear here after your account activity is available.',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 10.5,
          height: 1.4,
        ),
      ),
    );
  }
}
