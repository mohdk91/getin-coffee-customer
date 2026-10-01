import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 225 renders only Laravel driver GPS without preview ETA', () {
    final source =
        File('lib/features/orders/tracking/live_driver_tracking_card.dart')
            .readAsStringSync();

    expect(source, contains('LiveDriverTrackingRepository'));
    expect(source, contains("'Straight-line distance'"));
    expect(source, contains("'GPS accuracy'"));
    expect(source, contains("'stale' => 'STALE'"));
    expect(source, isNot(contains('GETIN_TRACKING_PREVIEW')));
    expect(source, isNot(contains('_PreviewDriverTracker')));
    expect(source, isNot(contains('etaMinutes')));
    expect(source, isNot(contains('Estimated arrival')));
  });
}
