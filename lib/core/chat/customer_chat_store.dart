import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/customer_repository.dart';
import '../engagement/customer_engagement_api_repository.dart';

enum CustomerChatAuthor { customer, getin, driver, system }

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
  CustomerEngagementApiRepository? _repository;
  bool _initialized = false;
  final List<CustomerChatMessage> _messages = <CustomerChatMessage>[];
  final Map<String, int> _conversationIds = <String, int>{};

  bool get usesApi => _repository?.usesApi ?? false;

  static Future<void> initialize([CustomerRepositoryContext? context]) =>
      instance._initialize(context);

  Future<void> _initialize([CustomerRepositoryContext? context]) async {
    if (_initialized) {
      return;
    }
    if (context != null) {
      _repository = CustomerEngagementApiRepository(context);
    }
    if (!usesApi) {
      _preferences = await SharedPreferences.getInstance();
      _load();
    }
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
    if (usesApi) {
      final conversation = await _repository!.openSupportChat(
        subject: 'Customer support',
      );
      await _loadConversation(supportThreadId, conversation);
      return;
    }
    if (messagesFor(supportThreadId).isNotEmpty) {
      return;
    }
    await addMessage(
      threadId: supportThreadId,
      author: CustomerChatAuthor.getin,
      text: 'Hi! How can GETIN support help you today?',
    );
  }

  Future<void> ensureDriverSeeded({
    required String orderId,
    required String driverName,
  }) async {
    await _ensureInitialized();
    final threadId = driverThreadId(orderId);
    if (usesApi) {
      final numericOrderId = int.tryParse(orderId);
      if (numericOrderId == null) {
        return;
      }
      final conversation = await _repository!.openDriverChat(numericOrderId);
      await _loadConversation(threadId, conversation);
      return;
    }
    if (messagesFor(threadId).isNotEmpty) {
      return;
    }
    await addMessage(
      threadId: threadId,
      author: CustomerChatAuthor.system,
      text:
          'Driver chat is available while your delivery is on the way. Avoid sharing passwords or payment details.',
    );
    await addMessage(
      threadId: threadId,
      author: CustomerChatAuthor.driver,
      text: 'Hi, I’m $driverName. I’m on the way with your GETIN order.',
    );
  }

  Future<void> addMessage({
    required String threadId,
    required CustomerChatAuthor author,
    required String text,
  }) async {
    await _ensureInitialized();
    final clean = text.trim();
    if (clean.isEmpty) {
      return;
    }

    if (usesApi && author == CustomerChatAuthor.customer) {
      final conversationId = _conversationIds[threadId];
      if (conversationId == null) {
        return;
      }
      final message = await _repository!.sendConversationMessage(
        conversationId: conversationId,
        body: clean,
      );
      _messages.add(_messageFromApi(threadId, message));
      notifyListeners();
      return;
    }

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
    if (!usesApi) {
      await _persist();
    }
    notifyListeners();
  }

  Future<void> _loadConversation(
    String threadId,
    Map<String, dynamic> summary,
  ) async {
    final id = (summary['id'] as num?)?.toInt();
    if (id == null) {
      return;
    }
    _conversationIds[threadId] = id;
    final conversation = await _repository!.conversation(id);
    final rawMessages = conversation['messages'];
    _messages.removeWhere((message) => message.threadId == threadId);
    if (rawMessages is List) {
      _messages.addAll(
        rawMessages.whereType<Map>().map(
              (raw) => _messageFromApi(
                threadId,
                Map<String, dynamic>.from(raw),
              ),
            ),
      );
    }
    notifyListeners();
  }

  CustomerChatMessage _messageFromApi(
    String threadId,
    Map<String, dynamic> json,
  ) {
    final sender = json['sender'];
    final userType = sender is Map ? sender['user_type']?.toString() : null;
    var author = CustomerChatAuthor.system;
    if (userType == 'customer') {
      author = CustomerChatAuthor.customer;
    } else if (userType == 'driver') {
      author = CustomerChatAuthor.driver;
    } else if (userType == 'employee' || userType == 'admin') {
      author = CustomerChatAuthor.getin;
    }
    return CustomerChatMessage(
      id: json['id']?.toString() ?? '',
      threadId: threadId,
      author: author,
      text: json['body']?.toString() ?? '',
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _initialize();
    }
  }

  void _load() {
    final raw = _preferences?.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }
      _messages
        ..clear()
        ..addAll(
          decoded.whereType<Map>().map(
                (entry) => CustomerChatMessage.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              ),
        );
    } catch (_) {
      _messages.clear();
    }
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    await preferences.setString(
      _storageKey,
      jsonEncode(_messages.map((message) => message.toJson()).toList()),
    );
  }
}
