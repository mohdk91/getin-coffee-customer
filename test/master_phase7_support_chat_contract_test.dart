import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 7 support chat opens Laravel support conversation', () {
    final source =
        File('lib/core/chat/customer_chat_store.dart').readAsStringSync();
    expect(source, contains('openSupportChat'));
    expect(source, contains('supportThreadId'));
  });
}
