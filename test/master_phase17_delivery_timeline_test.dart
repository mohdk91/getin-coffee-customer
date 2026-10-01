import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 180 consumes server delivery events instead of fabricating GPS state', () {
    final screen =
        File('lib/features/orders/live_order_detail_screen.dart').readAsStringSync();
    final service =
        File('lib/core/orders/live_order_lifecycle_service.dart').readAsStringSync();

    expect(screen, contains('loadDeliveryTimeline(widget.orderId)'));
    expect(screen, contains('_deliveryTimeline.isNotEmpty'));
    expect(screen, contains('entry.description'));
    expect(service, contains('LiveOrderTimelineEntry.fromDeliveryEvent'));
    expect(screen, isNot(contains('_PreviewDriverTracker')));
  });
}
