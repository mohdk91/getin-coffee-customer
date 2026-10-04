import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 198 routes API review actions through Laravel eligibility', () {
    final liveOrder = File(
      'lib/features/orders/live_order_detail_screen.dart',
    ).readAsStringSync();
    final orders =
        File('lib/features/orders/orders_screen.dart').readAsStringSync();

    expect(liveOrder, contains('loadOrderStatus('));
    expect(liveOrder, contains('force: true'));
    expect(liveOrder, contains('_reviewStatus!.delivery.eligible'));
    expect(liveOrder, contains('_reviewStatus!.employee.eligible'));
    expect(liveOrder, contains('Rate delivery driver'));
    expect(liveOrder, contains('Rate pickup employee'));
    expect(
      liveOrder,
      contains(
          'You can rate your delivery driver or pickup employee when available.'),
    );
    expect(
        orders, contains('onRate: (!controller.usesApi || !authenticated) &&'));
  });
}
