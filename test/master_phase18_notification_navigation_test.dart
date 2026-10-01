import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 192 routes trusted notification destinations after server read acknowledgement', () {
    final source = File('lib/features/notifications/notifications_screen.dart').readAsStringSync();

    expect(source, contains('await store.markRead(item.id);'));
    expect(source, contains('if (!context.mounted)'));
    expect(source, contains('item.actionRoute'));
    expect(source, contains('navigation.openOrders();'));
    expect(source, contains('navigation.openMenu();'));
    expect(source, contains('navigation.openMembership();'));
    expect(source, contains('navigation.openHome();'));
  });
}
