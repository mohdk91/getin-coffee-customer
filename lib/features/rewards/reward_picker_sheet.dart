import 'package:flutter/material.dart';

import '../../core/rewards/customer_rewards_store.dart';
import '../../core/theme/app_colors.dart';
import '../cart/cart_controller.dart';

Future<void> showRewardPickerSheet(
  BuildContext context, {
  required CartController cart,
}) async {
  final rewards = CustomerRewardsStore.instance;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return AnimatedBuilder(
        animation: Listenable.merge([cart, rewards]),
        builder: (context, child) {
          final active = rewards.activeRewards;
          final applied = cart.appliedReward;

          return SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.78,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use a reward',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Only rewards eligible for this cart can be applied.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.green,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: active.isEmpty
                        ? const _EmptyRewards()
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: active.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final redemption = active[index];
                              final definition = rewards.definitionFor(
                                redemption.definitionId,
                              );
                              final eligible =
                                  cart.isRewardApplicable(redemption);
                              final selected = applied?.id == redemption.id;

                              return _RewardOption(
                                title: definition.title,
                                code: redemption.code,
                                usageText: definition.usageText,
                                eligible: eligible,
                                selected: selected,
                                reason: eligible
                                    ? null
                                    : cart.rewardIneligibilityReason(
                                        redemption,
                                      ),
                                onTap: () {
                                  if (selected) {
                                    cart.removeReward();
                                    return;
                                  }

                                  if (!eligible) {
                                    ScaffoldMessenger.of(sheetContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          cart.rewardIneligibilityReason(
                                            redemption,
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  cart.applyReward(redemption.id);
                                  Navigator.pop(sheetContext);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _EmptyRewards extends StatelessWidget {
  const _EmptyRewards();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 14, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars_rounded,
            color: AppColors.gold,
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            'No redeemed rewards yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Redeem a reward from Profile → Rewards, then return here to use it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardOption extends StatelessWidget {
  final String title;
  final String code;
  final String usageText;
  final bool eligible;
  final bool selected;
  final String? reason;
  final VoidCallback onTap;

  const _RewardOption({
    required this.title,
    required this.code,
    required this.usageText,
    required this.eligible,
    required this.selected,
    required this.reason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF0E8D4) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.workspace_premium_rounded,
                  color: selected ? AppColors.green : AppColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          selected
                              ? 'APPLIED'
                              : eligible
                                  ? 'USE'
                                  : 'NOT ELIGIBLE',
                          style: TextStyle(
                            color: selected || eligible
                                ? AppColors.green
                                : AppColors.muted,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      code,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      eligible ? usageText : reason ?? usageText,
                      style: TextStyle(
                        color: eligible ? AppColors.muted : Colors.red.shade400,
                        fontSize: 9.5,
                        height: 1.35,
                      ),
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
