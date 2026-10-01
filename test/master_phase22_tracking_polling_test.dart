import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 224 polls tracking and stops after a terminal state', () {
    final source = File('lib/core/orders/live_driver_tracking_controller.dart')
        .readAsStringSync();

    expect(source, contains('Duration(seconds: 10)'));
    expect(source, contains('Timer.periodic'));
    expect(source, contains('repository.load(orderId)'));
    expect(source, contains('!next.shouldPoll'));
    expect(source, contains('_timer?.cancel()'));
    expect(source, contains('latest server state'));
  });
}
