import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/rewards/customer_rewards_store.dart';
import 'package:getin_coffee/features/cart/cart_controller.dart';

void main() {
  final rewards = CustomerRewardsStore.instance;
  final cart = CartController.instance;

  CartItem largeDrink() {
    return const CartItem(
      name: 'Iced Latte',
      description: 'Test drink',
      image: 'assets/images/products/iced_latte.png',
      branchName: 'Getin Stanley',
      serviceType: 'delivery',
      currency: 'EGP',
      basePrice: 65,
      unitPrice: 75,
      quantity: 1,
      size: 'Large',
      temperature: 'Iced',
      milk: 'Full Fat',
      strength: 'Regular',
      sweetness: 'Regular',
      addOns: [],
    );
  }

  setUp(() {
    cart.clear();
    rewards.resetToDemoDefaults();
  });

  test('insufficient Stars prevents Free Drink redemption', () {
    final freeDrink = CustomerRewardsStore.catalog.firstWhere(
      (reward) => reward.id == 'free-drink',
    );

    final result = rewards.redeem(freeDrink);

    expect(result, RewardRedeemResult.insufficientStars);
    expect(rewards.stars, 120);
  });

  test('successful redemption deducts Stars and creates reward', () {
    final upgrade = CustomerRewardsStore.catalog.firstWhere(
      (reward) => reward.id == 'free-size-upgrade',
    );

    final result = rewards.redeem(upgrade);

    expect(result, RewardRedeemResult.success);
    expect(rewards.stars, 40);
    expect(
      rewards.redeemedRewards.first.definitionId,
      'free-size-upgrade',
    );
    expect(
      rewards.redeemedRewards.first.status,
      RewardRedemptionStatus.available,
    );
  });

  test('redeemed free size upgrade applies EGP 10 in cart', () {
    final upgrade = CustomerRewardsStore.catalog.firstWhere(
      (reward) => reward.id == 'free-size-upgrade',
    );
    rewards.redeem(upgrade);
    final redemption = rewards.redeemedRewards.first;

    cart.addOrMerge(largeDrink());

    expect(cart.applyReward(redemption.id), isTrue);
    expect(cart.rewardDiscount, 10);
    expect(
      rewards.redeemedById(redemption.id)?.status,
      RewardRedemptionStatus.applied,
    );
  });

  test('demo order marks applied reward as used', () {
    final existingFreeDrink = rewards.redeemedRewards.firstWhere(
      (reward) => reward.definitionId == 'free-drink',
    );

    cart.addOrMerge(largeDrink());
    expect(cart.applyReward(existingFreeDrink.id), isTrue);
    expect(cart.rewardDiscount, 75);

    cart.completeDemoOrder();

    expect(cart.isEmpty, isTrue);
    expect(
      rewards.redeemedById(existingFreeDrink.id)?.status,
      RewardRedemptionStatus.used,
    );
  });
}
