import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 229 keeps Customer delivery tracking server authoritative', () {
    final repository =
        File('lib/core/orders/live_driver_tracking_repository.dart')
            .readAsStringSync();
    final ordersApi =
        File('lib/core/orders/customer_orders_api_repository.dart')
            .readAsStringSync();
    final controller = File('lib/core/orders/live_driver_tracking_controller.dart')
        .readAsStringSync();
    final card =
        File('lib/features/orders/tracking/live_driver_tracking_card.dart')
            .readAsStringSync();
    final detail = File('lib/features/orders/live_order_detail_screen.dart')
        .readAsStringSync();
    final demoDetail = File('lib/features/orders/order_detail_screen.dart')
        .readAsStringSync();

    expect(repository, contains('_orders.driverLocation(orderId)'));
    expect(ordersApi, contains('/driver-location'));
    expect(repository, contains("quality['is_fresh']"));
    expect(repository, contains("quality['is_accurate']"));
    expect(controller, contains('Timer.periodic'));
    expect(controller, contains('!next.shouldPoll'));
    expect(card, contains('LiveDriverTrackingRepository'));
    expect(card, contains('Straight-line distance'));
    expect(card, isNot(contains('GETIN_TRACKING_PREVIEW')));
    expect(card, isNot(contains('_PreviewDriverTracker')));
    expect(card, isNot(contains('Estimated arrival')));
    expect(detail, contains('LiveDriverTrackingCard('));
    expect(detail, contains('onMessageDriver: _openDriverChat'));
    expect(demoDetail, isNot(contains('LiveDriverTrackingCard(')));
    expect(demoDetail, contains('Demo order tracking is local-only'));
  });
}
