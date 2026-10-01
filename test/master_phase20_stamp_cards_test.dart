import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/rewards/customer_stamp_card_store.dart';

void main() {
  test('Task 206 parses Laravel stamp campaign and card state', () {
    final snapshot = CustomerStampCardSnapshot.fromApi(
      const <String, dynamic>{
        'campaign': <String, dynamic>{
          'id': 5,
          'name': 'Morning Cups',
          'description': 'Collect five qualifying drinks.',
          'required_stamps': 5,
          'stamps_per_order': 1,
          'reward': <String, dynamic>{'type': 'points', 'points': 25},
        },
        'card': <String, dynamic>{
          'stamps': 3,
          'remaining': 2,
          'completion_count': 1,
          'status': 'active',
        },
      },
    );

    expect(snapshot.campaignName, 'Morning Cups');
    expect(snapshot.requiredStamps, 5);
    expect(snapshot.remaining, 2);
    expect(snapshot.rewardLabel, '25 Stars');
  });

  test('Task 206 rewards UI uses server campaign copy', () {
    final source = File('lib/features/rewards/rewards_screen.dart').readAsStringSync();
    expect(source, contains('stampStore.campaignName'));
    expect(source, contains('stampStore.campaignDescription'));
    expect(source, contains('stampStore.rewardLabel'));
  });
}
