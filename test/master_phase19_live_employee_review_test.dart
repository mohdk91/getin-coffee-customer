import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 200 rechecks server pickup-employee eligibility before submit', () {
    final store = File(
      'lib/core/reviews/customer_review_store.dart',
    ).readAsStringSync();

    expect(store, contains('Future<bool> submitLiveEmployeeReview'));
    expect(store, contains('status?.employee.eligible != true'));
    expect(store, contains('_repository!.submitEmployeeReview('));
    expect(store, contains('refreshed?.employee.submitted == true'));
    expect(store, contains('return submitLiveEmployeeReview('));
  });
}
