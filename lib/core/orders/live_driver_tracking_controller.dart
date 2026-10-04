import 'dart:async';

import 'package:flutter/foundation.dart';

import 'live_driver_tracking_repository.dart';

class LiveDriverTrackingController extends ChangeNotifier {
  final LiveDriverTrackingRepository repository;
  final int orderId;
  final Duration interval;

  LiveDriverTrackingSnapshot? _snapshot;
  String? _errorMessage;
  bool _loading = false;
  bool _disposed = false;
  bool _active = false;
  Timer? _timer;

  LiveDriverTrackingController({
    required this.repository,
    required this.orderId,
    this.interval = const Duration(seconds: 10),
  });

  LiveDriverTrackingSnapshot? get snapshot => _snapshot;
  String? get errorMessage => _errorMessage;
  bool get loading => _loading;

  Future<void> start() async {
    if (_disposed) return;
    _active = true;
    await refresh();
    _schedule();
  }

  void pause() {
    if (_disposed || !_active) return;
    _active = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> resume() async {
    if (_disposed || _active || _snapshot?.shouldPoll == false) return;
    _active = true;
    await refresh();
    _schedule();
  }

  Future<void> refresh() async {
    if (_disposed || _loading) return;
    _loading = true;
    notifyListeners();

    try {
      final next = await repository.load(orderId);
      if (_disposed) return;
      _snapshot = next;
      _errorMessage = null;
      if (!next.shouldPoll) {
        _timer?.cancel();
        _timer = null;
      }
    } catch (_) {
      if (_disposed) return;
      _errorMessage =
          'Driver location could not be refreshed. Showing the latest available location.';
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void _schedule() {
    if (_disposed ||
        !_active ||
        _snapshot?.shouldPoll == false ||
        _timer != null) {
      return;
    }
    _timer = Timer.periodic(interval, (_) {
      unawaited(refresh());
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _active = false;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
