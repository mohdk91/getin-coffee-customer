import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/customer_repository.dart';
import '../engagement/customer_engagement_api_repository.dart';

enum PlayGameType { spinWin, stopTimer }

class PlayHistoryEntry {
  final String id;
  final PlayGameType game;
  final String resultTitle;
  final String rewardText;
  final DateTime playedAt;
  const PlayHistoryEntry({
    required this.id,
    required this.game,
    required this.resultTitle,
    required this.rewardText,
    required this.playedAt,
  });
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'game': game.name,
        'resultTitle': resultTitle,
        'rewardText': rewardText,
        'playedAt': playedAt.toIso8601String(),
      };
  static PlayHistoryEntry? fromJson(Map<String, Object?> json) {
    final gameName = json['game'] as String?;
    final playedAt = DateTime.tryParse(json['playedAt'] as String? ?? '');
    if (gameName == null || playedAt == null) {
      return null;
    }
    final matches =
        PlayGameType.values.where((value) => value.name == gameName);
    if (matches.isEmpty) {
      return null;
    }
    return PlayHistoryEntry(
      id: json['id'] as String? ?? '',
      game: matches.first,
      resultTitle: json['resultTitle'] as String? ?? '',
      rewardText: json['rewardText'] as String? ?? '',
      playedAt: playedAt,
    );
  }
}

class CustomerPlayStore extends ChangeNotifier {
  CustomerPlayStore._();
  static final CustomerPlayStore instance = CustomerPlayStore._();

  static const String _spinDateKey = 'getin_demo_play_spin_date_v1';
  static const String _timerDateKey = 'getin_demo_play_timer_date_v1';
  static const String _historyKey = 'getin_demo_play_history_v1';

  SharedPreferences? _preferences;
  CustomerEngagementApiRepository? _repository;
  String? _spinPlayedDate;
  String? _timerPlayedDate;
  bool _apiEligible = false;
  int _attemptsRemaining = 0;
  List<PlayHistoryEntry> _history = <PlayHistoryEntry>[];

  bool get usesApi => _repository?.usesApi ?? false;
  List<PlayHistoryEntry> get history => List.unmodifiable(_history);

  static Future<void> initialize([CustomerRepositoryContext? context]) async {
    final store = instance;
    if (context != null) {
      store._repository = CustomerEngagementApiRepository(context);
    }
    if (store.usesApi) {
      await store.refresh();
      return;
    }
    store._preferences = await SharedPreferences.getInstance();
    store._spinPlayedDate = store._preferences?.getString(_spinDateKey);
    store._timerPlayedDate = store._preferences?.getString(_timerDateKey);
    store._history =
        store._decodeHistory(store._preferences?.getString(_historyKey));
  }

  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null || !repository.usesApi) {
      return;
    }
    final status = await repository.playStatus();
    _apiEligible = status['eligible'] == true;
    _attemptsRemaining = (status['attempts_remaining'] as num?)?.toInt() ?? 0;
    final history = await repository.playHistory();
    _history = history.map(_fromApi).toList(growable: false);
    notifyListeners();
  }

  bool canPlay(PlayGameType game, {DateTime? now}) {
    if (usesApi) {
      return _apiEligible && _attemptsRemaining > 0;
    }
    final today = _dateKey(now ?? DateTime.now());
    return game == PlayGameType.spinWin
        ? _spinPlayedDate != today
        : _timerPlayedDate != today;
  }

  DateTime nextReset({DateTime? now}) {
    final current = now ?? DateTime.now();
    return DateTime(current.year, current.month, current.day + 1);
  }

  PlayHistoryEntry? latestFor(PlayGameType game) {
    for (final entry in _history) {
      if (entry.game == game) {
        return entry;
      }
    }
    return null;
  }

  Future<PlayHistoryEntry> recordPlay({
    required PlayGameType game,
    required String resultTitle,
    required String rewardText,
    DateTime? playedAt,
  }) async {
    if (usesApi) {
      final attempt = await _repository!.playAttempt();
      final authoritative = _fromApi(attempt, fallbackGame: game);
      await refresh();
      for (final entry in _history) {
        if (entry.id == authoritative.id) return entry;
      }
      return authoritative;
    }

    final timestamp = playedAt ?? DateTime.now();
    final date = _dateKey(timestamp);
    if (game == PlayGameType.spinWin) {
      _spinPlayedDate = date;
    } else {
      _timerPlayedDate = date;
    }
    final entry = PlayHistoryEntry(
      id: '${game.name}-${timestamp.microsecondsSinceEpoch}',
      game: game,
      resultTitle: resultTitle,
      rewardText: rewardText,
      playedAt: timestamp,
    );
    _history.insert(0, entry);
    if (_history.length > 20) {
      _history = _history.take(20).toList(growable: false);
    }
    notifyListeners();
    await _persist();
    return entry;
  }

  PlayHistoryEntry _fromApi(Map<String, dynamic> json,
      {PlayGameType fallbackGame = PlayGameType.spinWin}) {
    final prize = json['prize'];
    final reward = json['reward'];
    final prizeName = prize is Map ? prize['name']?.toString() : null;
    final rewardType = reward is Map ? reward['type']?.toString() : null;
    final result = json['result']?.toString() ?? 'completed';
    return PlayHistoryEntry(
      id: json['id']?.toString() ?? '',
      game: fallbackGame,
      resultTitle: prizeName ?? (result == 'win' ? 'You won!' : 'Getin Play'),
      rewardText: rewardType ??
          (result == 'win' ? 'Reward issued' : 'No prize this time'),
      playedAt: DateTime.tryParse(json['played_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  @visibleForTesting
  Future<void> resetToDemoDefaults({bool persist = false}) async {
    _spinPlayedDate = null;
    _timerPlayedDate = null;
    _history = <PlayHistoryEntry>[];
    notifyListeners();
    if (persist) {
      await _persist();
    }
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    if (_spinPlayedDate == null) {
      await preferences.remove(_spinDateKey);
    } else {
      await preferences.setString(_spinDateKey, _spinPlayedDate!);
    }
    if (_timerPlayedDate == null) {
      await preferences.remove(_timerDateKey);
    } else {
      await preferences.setString(_timerDateKey, _timerPlayedDate!);
    }
    await preferences.setString(_historyKey,
        jsonEncode(_history.map((entry) => entry.toJson()).toList()));
  }

  List<PlayHistoryEntry> _decodeHistory(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <PlayHistoryEntry>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <PlayHistoryEntry>[];
      }
      return decoded
          .whereType<Map>()
          .map((entry) =>
              PlayHistoryEntry.fromJson(Map<String, Object?>.from(entry)))
          .whereType<PlayHistoryEntry>()
          .toList(growable: false);
    } catch (_) {
      return <PlayHistoryEntry>[];
    }
  }

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
