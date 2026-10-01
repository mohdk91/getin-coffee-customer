import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/reviews/customer_review_store.dart';

void main() {
  test('Task 197 parses Laravel order review eligibility', () {
    final status = CustomerOrderReviewStatus.fromJson(
      const <String, dynamic>{
        'order': <String, dynamic>{
          'id': 77,
          'order_number': 'GC-77',
          'order_type': 'delivery',
          'status': 'completed',
        },
        'delivery': <String, dynamic>{
          'eligible': true,
          'submitted': false,
          'reason': null,
        },
        'employee': <String, dynamic>{
          'eligible': false,
          'submitted': false,
          'reason': 'not_pickup_order',
        },
      },
    );

    expect(status.orderId, 77);
    expect(status.delivery.eligible, isTrue);
    expect(status.employee.eligible, isFalse);
    expect(status.employee.reason, 'not_pickup_order');
    expect(status.hasEligibleReview, isTrue);
  });
}
