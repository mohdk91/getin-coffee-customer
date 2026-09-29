import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/products/product_type.dart';
import 'package:getin_coffee/core/rewards/customer_rewards_store.dart';
import 'package:getin_coffee/core/rewards/customer_stamp_card_store.dart';
import 'package:getin_coffee/core/rewards/reward_earning_policy.dart';

void main() {
  test('EGP 65 earns 6 base Stars and 9 member Stars', () {
    expect(
      RewardEarningPolicy.starsForAmount(65, isMember: false),
      6,
    );
    expect(
      RewardEarningPolicy.starsForAmount(65, isMember: true),
      9,
    );
  });

  test('only beverage product types earn Getin stamps', () {
    expect(RewardEarningPolicy.earnsStamp(ProductType.drink), isTrue);
    expect(RewardEarningPolicy.earnsStamp(ProductType.refreshment), isTrue);
    expect(RewardEarningPolicy.earnsStamp(ProductType.food), isFalse);
    expect(RewardEarningPolicy.earnsStamp(ProductType.bakery), isFalse);
    expect(RewardEarningPolicy.earnsStamp(ProductType.merchandise), isFalse);
  });

  test('7-stamp card completes and carries remainder', () {
    final stamps = CustomerStampCardStore.instance;
    stamps.resetToDemoDefaults();

    final first = stamps.addEligibleDrinks(3);
    expect(first.cardsCompleted, 1);
    expect(first.currentStamps, 0);

    final second = stamps.addEligibleDrinks(8);
    expect(second.cardsCompleted, 1);
    expect(second.currentStamps, 1);
  });

  test('stamp completion can grant free drink without spending Stars', () {
    final rewards = CustomerRewardsStore.instance;
    rewards.resetToDemoDefaults();
    final starsBefore = rewards.stars;
    final rewardsBefore = rewards.redeemedRewards.length;

    final reward = rewards.grantFreeDrinkReward(source: 'test-stamp-card');

    expect(reward.definitionId, 'free-drink');
    expect(reward.status, RewardRedemptionStatus.available);
    expect(rewards.stars, starsBefore);
    expect(rewards.redeemedRewards.length, rewardsBefore + 1);
  });
}
