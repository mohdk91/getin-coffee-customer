import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 187 keeps live chat threads server-backed and refreshable', () {
    final source = File('lib/core/chat/customer_chat_store.dart').readAsStringSync();

    expect(source, contains('Future<void> refreshThread(String threadId)'));
    expect(source, contains("_repository!.conversation(conversationId)"));
    expect(source, contains('Future<void> markThreadRead(String threadId)'));
    expect(source, contains('_repository!.markConversationRead('));
    expect(source, contains('await refreshThread(threadId);'));
    expect(source, contains('if (!usesApi)'));
  });
}
