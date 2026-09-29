import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlayGameType {
  spinWin,
  stopTimer,
}

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
    final id = json['id'] as String?;
    final gameName = json['game'] as String?;
    final resultTitle = json['resultTitle'] as String?;
    final rewardText = json['rewardText'] as String?;
    final playedAt = DateTime.tryParse(json['playedAt'] as String? ?? '');

    if (id == null ||
        gameName == null ||
        resultTitle == null ||
        rewardText == null ||
        playedAt == null) {
      return null;
    }

    final matches =
        PlayGameType.values.where((value) => value.name == gameName);
    if (matches.isEmpty) return null;

    return PlayHistoryEntry(
      id: id,
      game: matches.first,
      resultTitle: resultTitle,
      rewardText: rewardText,
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
  String? _spinPlayedDate;
  String? _timerPlayedDate;
  List<PlayHistoryEntry> _history = <PlayHistoryEntry>[];

  List<PlayHistoryEntry> get history => List.unmodifiable(_history);

  static Future<void> initialize() async {
    final store = instance;
    store._preferences = await SharedPreferences.getInstance();
    store._spinPlayedDate = store._preferences?.getString(_spinDateKey);
    store._timerPlayedDate = store._preferences?.getString(_timerDateKey);
    store._history = store._decodeHistory(
      store._preferences?.getString(_historyKey),
    );
  }

  bool canPlay(PlayGameType game, {DateTime? now}) {
    final today = _dateKey(now ?? DateTime.now());
    switch (game) {
      case PlayGameType.spinWin:
        return _spinPlayedDate != today;
      case PlayGameType.stopTimer:
        return _timerPlayedDate != today;
    }
  }

  DateTime nextReset({DateTime? now}) {
    final current = now ?? DateTime.now();
    return DateTime(current.year, current.month, current.day + 1);
  }

  PlayHistoryEntry? latestFor(PlayGameType game) {
    for (final entry in _history) {
      if (entry.game == game) return entry;
    }
    return null;
  }

  Future<void> recordPlay({
    required PlayGameType game,
    required String resultTitle,
    required String rewardText,
    DateTime? playedAt,
  }) async {
    final timestamp = playedAt ?? DateTime.now();
    final date = _dateKey(timestamp);

    switch (game) {
      case PlayGameType.spinWin:
        _spinPlayedDate = date;
        break;
      case PlayGameType.stopTimer:
        _timerPlayedDate = date;
        break;
    }

    _history.insert(
      0,
      PlayHistoryEntry(
        id: '${game.name}-${timestamp.microsecondsSinceEpoch}',
        game: game,
        resultTitle: resultTitle,
        rewardText: rewardText,
        playedAt: timestamp,
      ),
    );
    if (_history.length > 20) {
      _history = _history.take(20).toList(growable: false);
    }

    notifyListeners();
    await _persist();
  }

  @visibleForTesting
  Future<void> resetToDemoDefaults({bool persist = false}) async {
    _spinPlayedDate = null;
    _timerPlayedDate = null;
    _history = <PlayHistoryEntry>[];
    notifyListeners();
    if (persist) await _persist();
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) return;

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

    await preferences.setString(
      _historyKey,
      jsonEncode(_history.map((entry) => entry.toJson()).toList()),
    );
  }

  List<PlayHistoryEntry> _decodeHistory(String? raw) {
    if (raw == null || raw.isEmpty) return <PlayHistoryEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <PlayHistoryEntry>[];
      return decoded
          .whereType<Map>()
          .map(
            (entry) => PlayHistoryEntry.fromJson(
              Map<String, Object?>.from(entry),
            ),
          )
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
