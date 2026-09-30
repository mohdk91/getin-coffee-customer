import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 7 notifications screen uses live notification store', () {
    final source = File(
      'lib/features/notifications/notifications_screen.dart',
    ).readAsStringSync();
    expect(source, contains('CustomerNotificationsStore.instance'));
    expect(source, isNot(contains('_DemoNotification')));
  });
}
