import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/membership/customer_membership_store.dart';
import '../../core/navigation/app_navigation_controller.dart';
import '../../core/rewards/customer_rewards_store.dart';
import '../../core/rewards/customer_stamp_card_store.dart';
import '../../core/theme/app_colors.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_screen.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  CustomerRewardsStore get _rewards => CustomerRewardsStore.instance;
  CartController get _cart => CartController.instance;

  IconData _iconFor(RewardBenefitType type) {
    switch (type) {
      case RewardBenefitType.freeDrink:
        return Icons.local_cafe_rounded;
      case RewardBenefitType.freeSizeUpgrade:
        return Icons.upgrade_rounded;
    }
  }

  String _statusLabel(RewardRedemptionStatus status) {
    switch (status) {
      case RewardRedemptionStatus.available:
        return 'AVAILABLE';
      case RewardRedemptionStatus.applied:
        return 'APPLIED';
      case RewardRedemptionStatus.used:
        return 'USED';
    }
  }

  Future<void> _openRewardDetails(
    BuildContext context,
    RewardDefinition definition,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            _rewards,
            CustomerStampCardStore.instance,
            CustomerMembershipStore.instance,
          ]),
          builder: (context, child) {
            final enough = _rewards.stars >= definition.starsRequired;
            final missing = definition.starsRequired - _rewards.stars;

            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Icon(
                          _iconFor(definition.benefitType),
                          color: AppColors.beige,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        definition.title,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        definition.description,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _InfoRow(
                        label: 'Your Stars',
                        value: '${_rewards.stars}',
                      ),
                      _InfoRow(
                        label: 'Required Stars',
                        value: '${definition.starsRequired}',
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      const Text(
                        'Where you can use it',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        definition.usageText,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: enough
                              ? () async {
                                  final confirmed = await showDialog<bool>(
                                    context: sheetContext,
                                    builder: (dialogContext) {
                                      return AlertDialog(
                                        title: const Text('Redeem reward?'),
                                        content: Text(
                                          'Redeem ${definition.starsRequired} Stars for ${definition.title}? Your current balance is ${_rewards.stars} Stars.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppColors.green,
                                              foregroundColor: AppColors.beige,
                                            ),
                                            child: const Text('Redeem'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmed != true) {
                                    return;
                                  }

                                  final result =
                                      await _rewards.redeemLive(definition);
                                  if (!sheetContext.mounted) {
                                    return;
                                  }

                                  if (result ==
                                      RewardRedeemResult.insufficientStars) {
                                    ScaffoldMessenger.of(sheetContext)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'You do not have enough Stars for this reward.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final redemption =
                                      _rewards.redeemedRewards.firstWhere(
                                    (reward) =>
                                        reward.definitionId == definition.id,
                                  );

                                  Navigator.pop(sheetContext);

                                  if (!context.mounted) {
                                    return;
                                  }

                                  await _showRedeemedSuccess(
                                    context,
                                    definition,
                                    redemption,
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.stars_rounded),
                          label: Text(
                            enough
                                ? 'Redeem ${definition.starsRequired} Stars'
                                : 'Need $missing more Stars',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: AppColors.beige,
                            disabledBackgroundColor: AppColors.border,
                            disabledForegroundColor: AppColors.muted,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRedeemedSuccess(
    BuildContext context,
    RewardDefinition definition,
    RedeemedReward redemption,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.green,
            size: 42,
          ),
          title: const Text('Reward redeemed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${definition.title} is now in your rewards wallet.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              SelectableText(
                redemption.code,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _useReward(context, redemption);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.beige,
              ),
              child: const Text('Use in Cart'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _useReward(
    BuildContext context,
    RedeemedReward redemption,
  ) async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Your reward is saved. Add an eligible item to your cart first.',
          ),
          action: SnackBarAction(
            label: 'MENU',
            onPressed: () {
              AppNavigationController.instance.openMenu();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
      return;
    }

    if (!_cart.isRewardApplicable(redemption)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _cart.rewardIneligibilityReason(redemption),
          ),
        ),
      );
      return;
    }

    _cart.applyReward(redemption.id);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CartScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _rewards,
        CustomerStampCardStore.instance,
        CustomerMembershipStore.instance,
      ]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.green,
            elevation: 0,
            title: const Text(
              'Rewards',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              _RewardsHero(
                stars: _rewards.stars,
                target: _rewards.nextRewardTarget,
                remaining: _rewards.starsUntilNextReward,
              ),
              const SizedBox(height: 12),
              _MembershipEarningCard(
                active: CustomerMembershipStore.instance.isActive,
                multiplier:
                    CustomerMembershipStore.instance.earningMultiplierLabel,
              ),
              const SizedBox(height: 12),
              _StampCard(
                current: CustomerStampCardStore.instance.currentStamps,
                completed: CustomerStampCardStore.instance.completedCards,
                memberActive: CustomerMembershipStore.instance.isActive,
              ),
              const SizedBox(height: 20),
              const _SectionTitle('Available Rewards'),
              const SizedBox(height: 9),
              ...CustomerRewardsStore.catalog.map(
                (definition) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RewardCatalogCard(
                    definition: definition,
                    currentStars: _rewards.stars,
                    icon: _iconFor(definition.benefitType),
                    onTap: () => _openRewardDetails(context, definition),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _SectionTitle('My Redeemed Rewards'),
              const SizedBox(height: 9),
              if (_rewards.redeemedRewards.isEmpty)
                const _EmptyWalletCard()
              else
                ..._rewards.redeemedRewards.map(
                  (redemption) {
                    final definition = _rewards.definitionFor(
                      redemption.definitionId,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RedeemedRewardCard(
                        definition: definition,
                        redemption: redemption,
                        icon: _iconFor(definition.benefitType),
                        status: _statusLabel(redemption.status),
                        onCopy: () async {
                          await Clipboard.setData(
                            ClipboardData(text: redemption.code),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reward code copied.'),
                            ),
                          );
                        },
                        onUse: redemption.status == RewardRedemptionStatus.used
                            ? null
                            : () => _useReward(context, redemption),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 10),
              const _SectionTitle('Stars History'),
              const SizedBox(height: 9),
              _HistoryCard(entries: _rewards.history),
              const SizedBox(height: 12),
              _RewardsAuthorityNotice(live: _rewards.usesApi),
            ],
          ),
        );
      },
    );
  }
}

class _MembershipEarningCard extends StatelessWidget {
  final bool active;
  final String multiplier;

  const _MembershipEarningCard({
    required this.active,
    required this.multiplier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF0E8D4) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active ? AppColors.green : AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: active ? AppColors.gold : AppColors.green,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'Green Member' : 'GETIN Membership',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  active
                      ? '$multiplier Stars earning is active'
                      : 'Join to earn 1.5× Stars on eligible orders',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.7,
                  ),
                ),
              ],
            ),
          ),
          if (active)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.gold,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _StampCard extends StatelessWidget {
  final int current;
  final int completed;
  final bool memberActive;

  const _StampCard({
    required this.current,
    required this.completed,
    required this.memberActive,
  });

  @override
  Widget build(BuildContext context) {
    final stampStore = CustomerStampCardStore.instance;
    final remaining = stampStore.requiredStamps - current;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.beige.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_cafe_rounded,
                  color: AppColors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stampStore.campaignName,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stampStore.usesApi
                          ? stampStore.campaignDescription
                          : 'Each eligible drink earns 1 stamp. Collect 7 to unlock a free drink reward.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.8,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E8D4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$current / ${stampStore.requiredStamps}',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(
              CustomerStampCardStore.instance.requiredStamps,
              (index) => Expanded(
                child: Container(
                  height: 38,
                  margin: EdgeInsets.only(
                    right: index ==
                            CustomerStampCardStore.instance.requiredStamps - 1
                        ? 0
                        : 5,
                  ),
                  decoration: BoxDecoration(
                    color: index < current ? AppColors.green : AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          index < current ? AppColors.green : AppColors.border,
                    ),
                  ),
                  child: Icon(
                    index < current
                        ? Icons.local_cafe_rounded
                        : Icons.circle_outlined,
                    color: index < current ? AppColors.beige : AppColors.muted,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  remaining == 0
                      ? '${stampStore.rewardLabel} unlocked'
                      : '$remaining stamp${remaining == 1 ? '' : 's'} until ${stampStore.rewardLabel}',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$completed completed',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (memberActive &&
              CustomerMembershipStore.instance.hasBonusMultiplier) ...[
            const SizedBox(height: 8),
            Text(
              '${CustomerMembershipStore.instance.earningMultiplierLabel} tier Stars earning is active. Stamp earning follows the active campaign.',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 9.2,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardsHero extends StatelessWidget {
  final int stars;
  final int target;
  final int remaining;

  const _RewardsHero({
    required this.stars,
    required this.target,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        target <= 0 ? 1.0 : (stars / target).clamp(0.0, 1.0).toDouble();
    final message = remaining == 0
        ? 'You can redeem a reward now'
        : '$remaining Stars until your next reward';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR STARS',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$stars',
            style: const TextStyle(
              color: AppColors.beige,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '$stars / $target Stars',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.green,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _RewardCatalogCard extends StatelessWidget {
  final RewardDefinition definition;
  final int currentStars;
  final IconData icon;
  final VoidCallback onTap;

  const _RewardCatalogCard({
    required this.definition,
    required this.currentStars,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enough = currentStars >= definition.starsRequired;
    final missing = definition.starsRequired - currentStars;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      definition.title,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${definition.starsRequired} Stars',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      enough ? 'Ready to redeem' : 'Need $missing more Stars',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.5,
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

class _RedeemedRewardCard extends StatelessWidget {
  final RewardDefinition definition;
  final RedeemedReward redemption;
  final IconData icon;
  final String status;
  final VoidCallback onCopy;
  final VoidCallback? onUse;

  const _RedeemedRewardCard({
    required this.definition,
    required this.redemption,
    required this.icon,
    required this.status,
    required this.onCopy,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final used = redemption.status == RewardRedemptionStatus.used;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.green),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      definition.title,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      redemption.code,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: used ? AppColors.cream : const Color(0xFFF0E8D4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: used ? AppColors.muted : AppColors.green,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            definition.usageText,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy code'),
              ),
              const Spacer(),
              if (onUse != null)
                FilledButton(
                  onPressed: onUse,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.beige,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    redemption.status == RewardRedemptionStatus.applied
                        ? 'View Cart'
                        : 'Use Now',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<RewardHistoryEntry> entries;

  const _HistoryCard({required this.entries});

  String _date(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(entries.length, (index) {
          final entry = entries[index];
          final positive = entry.starsDelta >= 0;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                title: Text(
                  entry.title,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${_date(entry.occurredAt)}${entry.subtitle == null ? '' : ' · ${entry.subtitle}'}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 8.5,
                  ),
                ),
                trailing: Text(
                  '${positive ? '+' : ''}${entry.starsDelta}',
                  style: TextStyle(
                    color: positive ? AppColors.green : const Color(0xFFB94A48),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (index != entries.length - 1)
                const Divider(height: 1, color: AppColors.border),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10.5,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWalletCard extends StatelessWidget {
  const _EmptyWalletCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Redeem a reward and it will appear here ready for Cart and Checkout.',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 10.5,
          height: 1.4,
        ),
      ),
    );
  }
}

class _RewardsAuthorityNotice extends StatelessWidget {
  final bool live;

  const _RewardsAuthorityNotice({required this.live});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E8D4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.green, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              live
                  ? 'Stars, reward availability and redeemed vouchers are confirmed by your GETIN account.'
                  : 'Explore Stars, rewards and stamp benefits available with GETIN.',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 9.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
