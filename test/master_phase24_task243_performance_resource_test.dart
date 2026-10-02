import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/orders/live_driver_tracking_controller.dart';
import 'package:getin_coffee/core/orders/live_driver_tracking_repository.dart';

void main() {
  test('Task 243 pauses customer live tracking polling while inactive', () async {
    final repository = _FakeTrackingRepository();
    final controller = LiveDriverTrackingController(
      repository: repository,
      orderId: 77,
      interval: const Duration(milliseconds: 20),
    );
    addTearDown(controller.dispose);

    await controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 55));
    expect(repository.calls, greaterThanOrEqualTo(2));

    controller.pause();
    final pausedCalls = repository.calls;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(repository.calls, pausedCalls);

    await controller.resume();
    expect(repository.calls, pausedCalls + 1);
  });

  test('Task 243 wires app lifecycle to tracking pause and resume', () {
    final source = File(
      'lib/features/orders/tracking/live_driver_tracking_card.dart',
    ).readAsStringSync();

    expect(source, contains('with WidgetsBindingObserver'));
    expect(source, contains('didChangeAppLifecycleState'));
    expect(source, contains('_controller.pause()'));
    expect(source, contains('_controller.resume()'));
  });

  test('Task 243 parallelizes independent account bootstrap refreshes', () {
    final source = File(
      'lib/core/auth/customer_account_sync.dart',
    ).readAsStringSync();

    expect(source, contains('Future.wait<void>'));
    expect(source, contains('_bestEffort'));
    expect(source, contains('CustomerPaymentMethodStore.instance.refresh'));
    expect(source, contains('CustomerRewardsStore.instance.refresh'));
  });
}

class _FakeTrackingRepository implements LiveDriverTrackingRepository {
  int calls = 0;

  @override
  bool get usesApi => true;

  @override
  Future<LiveDriverTrackingSnapshot> load(int orderId) async {
    calls += 1;
    return LiveDriverTrackingSnapshot(
      orderId: orderId,
      state: 'live',
      available: true,
      reason: null,
      latitude: 31.2,
      longitude: 29.9,
      accuracyMeters: 8,
      recordedAt: DateTime.now(),
      receivedAt: DateTime.now(),
      ageSeconds: 1,
      isFresh: true,
      isAccurate: true,
      maxStaleSeconds: 30,
      maxAccuracyMeters: 50,
      destinationLatitude: 31.21,
      destinationLongitude: 29.91,
    );
  }
}
