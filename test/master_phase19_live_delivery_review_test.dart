import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 199 rechecks server delivery-review eligibility before submit', () {
    final store = File(
      'lib/core/reviews/customer_review_store.dart',
    ).readAsStringSync();

    expect(store, contains('Future<bool> submitLiveDeliveryReview'));
    expect(store, contains('status?.delivery.eligible != true'));
    expect(store, contains('_repository!.submitDeliveryReview('));
    expect(store, contains('refreshed?.delivery.submitted == true'));
    expect(
      store,
      contains('return submitLiveDeliveryReview('),
    );
  });
}
