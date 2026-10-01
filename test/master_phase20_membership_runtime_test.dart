import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/membership/customer_membership_store.dart';

void main() {
  test('Task 203 parses authoritative membership tier multipliers', () {
    final tier = CustomerMembershipTier.fromApi(
      const <String, dynamic>{
        'id': 2,
        'code': 'silver',
        'name': 'Silver',
        'minimum_lifetime_points': 500,
        'points_multiplier': '1.25',
        'benefits': <String, dynamic>{'birthday_reward': true},
      },
    );

    expect(tier.code, 'silver');
    expect(tier.pointsMultiplier, 1.25);
    expect(tier.hasBonusMultiplier, isTrue);
    expect(tier.multiplierLabel, '1.25×');
  });

  test('Task 203 consumes current next tier and percent_to_next', () {
    final source = File(
      'lib/core/membership/customer_membership_store.dart',
    ).readAsStringSync();

    expect(source, contains("data['current_tier']"));
    expect(source, contains("data['next_tier']"));
    expect(source, contains('repository.membershipTiers()'));
    expect(source, contains("progress['percent_to_next']"));
    expect(source, contains("progress['lifetime_points']"));
    expect(source, contains("progress['points_to_next']"));
  });
}
