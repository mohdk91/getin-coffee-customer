import '../products/product_type.dart';

class RewardEarningPolicy {
  const RewardEarningPolicy._();

  static const double egpPerStar = 10;
  static const double memberMultiplier = 1.5;

  static double parsePrice(String price) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(price);
    return double.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static int baseStarsForAmount(double amount) {
    if (amount <= 0) return 0;
    final stars = (amount / egpPerStar).floor();
    return stars < 1 ? 1 : stars;
  }

  static int starsForAmount(
    double amount, {
    required bool isMember,
    double? multiplier,
  }) {
    final base = baseStarsForAmount(amount);
    final appliedMultiplier = multiplier ?? (isMember ? memberMultiplier : 1);
    if (appliedMultiplier <= 1) return base;
    return (base * appliedMultiplier).round();
  }

  static int starsForPrice(
    String price, {
    required bool isMember,
    double? multiplier,
  }) {
    return starsForAmount(
      parsePrice(price),
      isMember: isMember,
      multiplier: multiplier,
    );
  }

  static bool earnsStamp(ProductType type) => type.isBeverage;
}
