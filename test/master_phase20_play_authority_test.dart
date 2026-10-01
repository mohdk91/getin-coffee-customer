import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 208 renders the server generated GETIN Play result', () {
    final store = File(
      'lib/core/rewards/customer_play_store.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/play/getin_play_screen.dart',
    ).readAsStringSync();

    expect(store, contains('Future<PlayHistoryEntry> recordPlay'));
    expect(store, contains('final authoritative = _fromApi(attempt'));
    expect(store, contains('await refresh();'));
    expect(screen, contains('play.usesApi ? result.resultTitle : prize.label'));
    expect(screen, contains('result.rewardText'));
    expect(screen, contains('prize selection and rewards are decided by GETIN'));
  });
}
