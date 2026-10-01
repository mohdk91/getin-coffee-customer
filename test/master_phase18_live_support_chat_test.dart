import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 188 keeps API support chat free of synthetic replies', () {
    final source = File('lib/features/chat/customer_support_chat_screen.dart').readAsStringSync();

    expect(source, contains("if (_store.usesApi)"));
    expect(source, contains('await _store.markThreadRead(CustomerChatStore.supportThreadId);'));
    expect(source, contains("'Live conversation · synced with GETIN'"));
    expect(source, contains('text: _demoReply(text)'));
    expect(source, contains('} else {'));
  });
}
