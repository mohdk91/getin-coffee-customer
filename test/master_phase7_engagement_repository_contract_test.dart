import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 7 engagement repository covers live customer surfaces', () {
    final source = File(
      'lib/core/engagement/customer_engagement_api_repository.dart',
    ).readAsStringSync();

    for (final path in <String>[
      '/v1/customer/loyalty',
      '/v1/customer/membership',
      '/v1/customer/rewards',
      '/v1/customer/stamp-cards',
      '/v1/customer/referral',
      '/v1/customer/gift-cards',
      '/v1/customer/play',
      '/v1/customer/reviews',
      '/v1/customer/notifications',
      '/v1/customer/conversations',
      '/v1/customer/support-conversations',
    ]) {
      expect(source, contains(path));
    }
  });
}
