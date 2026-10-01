import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 191 uses Laravel unread count in API mode', () {
    final source = File('lib/core/notifications/customer_notifications_store.dart').readAsStringSync();

    expect(source, contains('int _serverUnreadCount = 0;'));
    expect(source, contains('final unreadCount = await repository.notificationUnreadCount();'));
    expect(source, contains('_serverUnreadCount = unreadCount;'));
    expect(source, contains('usesApi\n      ? _serverUnreadCount'));
    expect(source, contains('_serverUnreadCount = 0;'));
  });
}
