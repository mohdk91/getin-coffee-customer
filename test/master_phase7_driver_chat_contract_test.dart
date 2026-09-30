import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 7 driver chat opens Laravel order conversation', () {
    final source =
        File('lib/core/chat/customer_chat_store.dart').readAsStringSync();
    expect(source, contains('openDriverChat'));
    expect(source, contains('sendConversationMessage'));
  });
}
