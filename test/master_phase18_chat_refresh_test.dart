import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 190 exposes server refresh and read acknowledgement in both chats', () {
    final support = File('lib/features/chat/customer_support_chat_screen.dart').readAsStringSync();
    final driver = File('lib/features/chat/driver_chat_screen.dart').readAsStringSync();

    for (final source in <String>[support, driver]) {
      expect(source, contains('Future<void> _refreshLiveThread()'));
      expect(source, contains('RefreshIndicator('));
      expect(source, contains('AlwaysScrollableScrollPhysics'));
      expect(source, contains('await _store.refreshThread('));
      expect(source, contains('await _store.markThreadRead('));
    }
  });
}
