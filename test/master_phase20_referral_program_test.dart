import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 207 uses authoritative referral program counts and rewards', () {
    final store = File(
      'lib/core/referrals/customer_referral_store.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/profile/profile_pages.dart',
    ).readAsStringSync();

    expect(store, contains("summary['referred_count']"));
    expect(store, contains("summary['rewarded_count']"));
    expect(store, contains("campaign['referrer_reward']"));
    expect(store, contains("summary['applied_referral'] is Map"));
    expect(profile, contains('referral.programHeadline'));
    expect(profile, contains("const ['Referred', 'Completed', 'Rewarded']"));
    expect(profile, contains('come from your GETIN account'));
  });
}
