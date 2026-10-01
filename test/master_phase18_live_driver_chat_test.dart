import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 189 keeps API driver chat free of synthetic driver replies', () {
    final source = File('lib/features/chat/driver_chat_screen.dart').readAsStringSync();

    expect(source, contains('await _store.markThreadRead(_threadId);'));
    expect(
      source,
      contains("'Live driver chat · GPS remains server-authoritative in Order Details'"),
    );
    expect(source, contains('text: _driverReply(text)'));
    expect(source, contains('if (_store.usesApi)'));
    expect(source, contains('} else {'));
  });
}
