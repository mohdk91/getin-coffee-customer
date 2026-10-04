import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Master Phase 7 production engagement wiring is present', () {
    final main = File('lib/core/bootstrap/customer_app_bootstrap.dart')
        .readAsStringSync();
    final repository = File(
      'lib/core/engagement/customer_engagement_api_repository.dart',
    ).readAsStringSync();
    final notifications = File(
      'lib/features/notifications/notifications_screen.dart',
    ).readAsStringSync();

    expect(main, contains('CustomerNotificationsStore.initialize'));
    expect(repository, contains('/v1/customer/rewards'));
    expect(repository, contains('/v1/customer/play/attempt'));
    expect(repository, contains('/v1/customer/conversations'));
    expect(notifications, isNot(contains('_DemoNotification')));
  });
}
