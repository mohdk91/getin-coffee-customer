import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CustomerChatAuthor {
  customer,
  getin,
  driver,
  system,
}

class CustomerChatMessage {
  final String id;
  final String threadId;
  final CustomerChatAuthor author;
  final String text;
  final DateTime sentAt;

  const CustomerChatMessage({
    required this.id,
    required this.threadId,
    required this.author,
    required this.text,
    required this.sentAt,
  });

  factory CustomerChatMessage.fromJson(Map<String, dynamic> json) {
    final authorName = json['author'] as String? ?? '';
    return CustomerChatMessage(
      id: json['id'] as String? ?? '',
      threadId: json['threadId'] as String? ?? '',
      author: CustomerChatAuthor.values.firstWhere(
        (value) => value.name == authorName,
        orElse: () => CustomerChatAuthor.system,
      ),
      text: json['text'] as String? ?? '',
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'threadId': threadId,
        'author': author.name,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };
}

class CustomerChatStore extends ChangeNotifier {
  CustomerChatStore._();

  static final CustomerChatStore instance = CustomerChatStore._();
  static const String _storageKey = 'getin_demo_chat_messages_v1';
  static const String supportThreadId = 'support:getin';

  SharedPreferences? _preferences;
  bool _initialized = false;
  final List<CustomerChatMessage> _messages = <CustomerChatMessage>[];

  static Future<void> initialize() => instance._initialize();

  Future<void> _initialize() async {
    if (_initialized) return;
    _preferences = await SharedPreferences.getInstance();
    _load();
    _initialized = true;
  }

  List<CustomerChatMessage> messagesFor(String threadId) {
    final result = _messages
        .where((message) => message.threadId == threadId)
        .toList(growable: false)
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return List<CustomerChatMessage>.unmodifiable(result);
  }

  String driverThreadId(String orderId) => 'driver:$orderId';

  Future<void> ensureSupportSeeded() async {
    await _ensureInitialized();
    if (messagesFor(supportThreadId).isNotEmpty) return;
    await addMessage(
      threadId: supportThreadId,
      author: CustomerChatAuthor.getin,
      text:
          'Hi! I’m the Getin demo support assistant. Choose a quick topic below or type your question.',
    );
  }

  Future<void> ensureDriverSeeded({
    required String orderId,
    required String driverName,
  }) async {
    await _ensureInitialized();
    final threadId = driverThreadId(orderId);
    if (messagesFor(threadId).isNotEmpty) return;
    await addMessage(
      threadId: threadId,
      author: CustomerChatAuthor.system,
      text:
          'Driver chat is available while your delivery is on the way. Avoid sharing passwords or payment details.',
    );
    await addMessage(
      threadId: threadId,
      author: CustomerChatAuthor.driver,
      text: 'Hi, I’m $driverName. I’m on the way with your Getin order.',
    );
  }

  Future<void> addMessage({
    required String threadId,
    required CustomerChatAuthor author,
    required String text,
  }) async {
    await _ensureInitialized();
    final clean = text.trim();
    if (clean.isEmpty) return;
    final now = DateTime.now();
    _messages.add(
      CustomerChatMessage(
        id: '${now.microsecondsSinceEpoch}-${_messages.length}',
        threadId: threadId,
        author: author,
        text: clean,
        sentAt: now,
      ),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> clearThread(String threadId) async {
    await _ensureInitialized();
    _messages.removeWhere((message) => message.threadId == threadId);
    await _persist();
    notifyListeners();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _initialize();
    }
  }

  void _load() {
    final raw = _preferences?.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _messages
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map(
                (entry) => CustomerChatMessage.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .where(
                (message) =>
                    message.threadId.isNotEmpty && message.text.isNotEmpty,
              ),
        );
    } catch (_) {
      _messages.clear();
    }
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) return;
    await preferences.setString(
      _storageKey,
      jsonEncode(_messages.map((message) => message.toJson()).toList()),
    );
  }
}
