import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StampEarnResult {
  final int stampsAdded;
  final int cardsCompleted;
  final int currentStamps;

  const StampEarnResult({
    required this.stampsAdded,
    required this.cardsCompleted,
    required this.currentStamps,
  });
}

class CustomerStampCardStore extends ChangeNotifier {
  CustomerStampCardStore._();

  static final CustomerStampCardStore instance = CustomerStampCardStore._();

  static const int stampsPerFreeDrink = 7;
  static const String _currentKey = 'getin_demo_stamp_current_v1';
  static const String _completedKey = 'getin_demo_stamp_completed_v1';
  static const String _totalKey = 'getin_demo_stamp_total_v1';

  SharedPreferences? _preferences;
  int _currentStamps = 4;
  int _completedCards = 0;
  int _totalStamps = 4;

  int get currentStamps => _currentStamps;
  int get completedCards => _completedCards;
  int get totalStamps => _totalStamps;
  int get remaining => stampsPerFreeDrink - _currentStamps;
  double get progress => _currentStamps / stampsPerFreeDrink;

  static Future<void> initialize() async {
    final store = instance;
    store._preferences = await SharedPreferences.getInstance();
    store._currentStamps =
        store._preferences?.getInt(_currentKey)?.clamp(0, 6).toInt() ?? 4;
    store._completedCards = store._preferences?.getInt(_completedKey) ?? 0;
    store._totalStamps = store._preferences?.getInt(_totalKey) ?? 4;
  }

  StampEarnResult addEligibleDrinks(int quantity) {
    if (quantity <= 0) {
      return StampEarnResult(
        stampsAdded: 0,
        cardsCompleted: 0,
        currentStamps: _currentStamps,
      );
    }

    final combined = _currentStamps + quantity;
    final completedNow = combined ~/ stampsPerFreeDrink;
    _currentStamps = combined % stampsPerFreeDrink;
    _completedCards += completedNow;
    _totalStamps += quantity;

    notifyListeners();
    unawaited(_persist());

    return StampEarnResult(
      stampsAdded: quantity,
      cardsCompleted: completedNow,
      currentStamps: _currentStamps,
    );
  }

  @visibleForTesting
  void resetToDemoDefaults({bool persist = false}) {
    _currentStamps = 4;
    _completedCards = 0;
    _totalStamps = 4;
    notifyListeners();
    if (persist) unawaited(_persist());
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) return;
    await preferences.setInt(_currentKey, _currentStamps);
    await preferences.setInt(_completedKey, _completedCards);
    await preferences.setInt(_totalKey, _totalStamps);
  }
}
