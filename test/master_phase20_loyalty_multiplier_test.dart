import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/rewards/reward_earning_policy.dart';

void main() {
  test('Task 204 supports Laravel membership multipliers', () {
    expect(
      RewardEarningPolicy.starsForAmount(
        100,
        isMember: true,
        multiplier: 1.25,
      ),
      13,
    );
    expect(
      RewardEarningPolicy.starsForAmount(
        100,
        isMember: true,
        multiplier: 1.5,
      ),
      15,
    );
  });

  test('Task 204 product surfaces consume authoritative multiplier', () {
    for (final path in <String>[
      'lib/features/home/home_section_listing_screen.dart',
      'lib/features/home/widgets/product_sections.dart',
      'lib/features/menu/menu_screen.dart',
      'lib/features/search/home_search_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('earningMultiplier'));
      expect(source, contains('earningMultiplierLabel'));
    }
  });
}
