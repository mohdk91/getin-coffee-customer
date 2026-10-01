import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 226 mounts live GPS only for active delivery orders', () {
    final source = File('lib/features/orders/live_order_detail_screen.dart')
        .readAsStringSync();

    expect(source, contains("import 'tracking/live_driver_tracking_card.dart';"));
    expect(source, contains('if (detail.isDelivery && !detail.isTerminal)'));
    expect(source, contains('LiveDriverTrackingCard(orderId: detail.id)'));
  });
}
