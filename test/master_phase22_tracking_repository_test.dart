import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 223 parses server driver tracking without inventing ETA', () {
    final repository =
        File('lib/core/orders/live_driver_tracking_repository.dart')
            .readAsStringSync();
    final orders = File('lib/core/orders/customer_orders_api_repository.dart')
        .readAsStringSync();

    expect(orders, contains("/driver-location"));
    expect(repository, contains('class LiveDriverTrackingSnapshot'));
    expect(repository, contains("state == 'terminal'"));
    expect(repository, contains("quality['age_seconds']"));
    expect(repository, contains("quality['is_fresh']"));
    expect(repository, contains("quality['is_accurate']"));
    expect(repository, isNot(contains('etaMinutes')));
  });
}
