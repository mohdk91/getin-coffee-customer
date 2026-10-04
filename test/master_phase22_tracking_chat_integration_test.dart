import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 227 keeps driver chat tied to the tracked live order', () {
    final detail = File('lib/features/orders/live_order_detail_screen.dart')
        .readAsStringSync();
    final chat =
        File('lib/features/chat/driver_chat_screen.dart').readAsStringSync();

    expect(detail, contains('onMessageDriver: _openDriverChat'));
    expect(detail, contains('DriverChatScreen('));
    expect(detail, contains('orderId: widget.orderId.toString()'));
    expect(chat, contains('live location is available in Order Details'));
    expect(chat, isNot(contains('demo route and ETA')));
  });
}
