import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/customer_repository.dart';
import '../engagement/customer_engagement_api_repository.dart';

enum GiftCardStatus { sent, received, redeemed }

enum GiftCardRedeemResult { success, invalidCode, alreadyRedeemed }

@immutable
class CustomerGiftCard {
  final String id;
  final String code;
  final double amount;
  final String currency;
  final String recipientName;
  final String recipientContact;
  final String message;
  final DateTime deliveryDate;
  final DateTime createdAt;
  final GiftCardStatus status;

  const CustomerGiftCard({
    required this.id,
    required this.code,
    required this.amount,
    required this.currency,
    required this.recipientName,
    required this.recipientContact,
    required this.message,
    required this.deliveryDate,
    required this.createdAt,
    required this.status,
  });

  CustomerGiftCard copyWith({GiftCardStatus? status}) => CustomerGiftCard(
        id: id,
        code: code,
        amount: amount,
        currency: currency,
        recipientName: recipientName,
        recipientContact: recipientContact,
        message: message,
        deliveryDate: deliveryDate,
        createdAt: createdAt,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'code': code,
        'amount': amount,
        'currency': currency,
        'recipientName': recipientName,
        'recipientContact': recipientContact,
        'message': message,
        'deliveryDate': deliveryDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
      };

  factory CustomerGiftCard.fromJson(Map<String, dynamic> json) {
    final status = GiftCardStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => GiftCardStatus.received,
    );
    return CustomerGiftCard(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'EGP',
      recipientName: json['recipientName']?.toString() ?? '',
      recipientContact: json['recipientContact']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      deliveryDate: DateTime.tryParse(json['deliveryDate']?.toString() ?? '') ??
          DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      status: status,
    );
  }
}

class CustomerGiftCardStore extends ChangeNotifier {
  CustomerGiftCardStore._();
  static final CustomerGiftCardStore instance = CustomerGiftCardStore._();

  static const _balanceKey = 'getin_demo_gift_card_balance_v1';
  static const _recordsKey = 'getin_demo_gift_cards_v1';

  CustomerEngagementApiRepository? _repository;
  double _balance = 0;
  final List<CustomerGiftCard> _cards = <CustomerGiftCard>[];

  bool get usesApi => _repository?.usesApi ?? false;
  double get balance => _balance;
  List<CustomerGiftCard> get cards => List.unmodifiable(_cards);
  List<CustomerGiftCard> get sentCards => _cards
      .where((card) => card.status == GiftCardStatus.sent)
      .toList(growable: false);
  List<CustomerGiftCard> get receivedCards => _cards
      .where((card) => card.status == GiftCardStatus.received)
      .toList(growable: false);
  List<CustomerGiftCard> get redeemedCards => _cards
      .where((card) => card.status == GiftCardStatus.redeemed)
      .toList(growable: false);

  static Future<void> initialize([CustomerRepositoryContext? context]) async {
    if (context != null) {
      instance._repository = CustomerEngagementApiRepository(context);
    }
    if (instance.usesApi) {
      await instance.refresh();
    } else {
      await instance._loadDemo();
    }
  }

  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null || !repository.usesApi) {
      return;
    }
    final items = await repository.giftCards();
    _cards
      ..clear()
      ..addAll(items.map(_fromApi));
    _balance = _cards
        .where((card) => card.status == GiftCardStatus.received)
        .fold<double>(0, (sum, card) => sum + card.amount);
    notifyListeners();
  }

  CustomerGiftCard _fromApi(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString().toLowerCase() ?? '';
    final balance = double.tryParse(json['balance']?.toString() ?? '') ?? 0;
    final original =
        double.tryParse(json['original_balance']?.toString() ?? '') ?? balance;
    final status = rawStatus.contains('exhaust') || balance <= 0
        ? GiftCardStatus.redeemed
        : GiftCardStatus.received;
    final lastFour = json['last_four']?.toString() ?? '';
    final issued = DateTime.tryParse(json['issued_at']?.toString() ?? '') ??
        DateTime.now();
    return CustomerGiftCard(
      id: json['id']?.toString() ?? '',
      code: lastFour.isEmpty ? 'GETIN CARD' : '•••• $lastFour',
      amount: original,
      currency: json['currency']?.toString() ?? 'EGP',
      recipientName: json['recipient_name']?.toString() ?? 'GETIN Customer',
      recipientContact: '',
      message: 'Server-managed GETIN gift card',
      deliveryDate: issued,
      createdAt: issued,
      status: status,
    );
  }

  Future<CustomerGiftCard> purchase({
    required double amount,
    required String recipientName,
    required String recipientContact,
    required String message,
    required DateTime deliveryDate,
    String currency = 'EGP',
  }) async {
    if (usesApi) {
      throw StateError(
        'Gift-card purchase is unavailable until a paid gift-card issuance endpoint is configured.',
      );
    }
    if (amount <= 0) {
      throw ArgumentError('Gift-card amount must be greater than zero.');
    }
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final code = 'GETIN-${stamp.toString().substring(7)}';
    final card = CustomerGiftCard(
      id: 'gift-$stamp',
      code: code,
      amount: amount,
      currency: currency,
      recipientName: recipientName.trim(),
      recipientContact: recipientContact.trim(),
      message: message.trim(),
      deliveryDate: deliveryDate,
      createdAt: DateTime.now(),
      status: GiftCardStatus.sent,
    );
    _cards.insert(0, card);
    await _saveDemo();
    notifyListeners();
    return card;
  }

  Future<GiftCardRedeemResult> redeemCode(String rawCode) async {
    final code = rawCode.trim();
    if (usesApi) {
      try {
        await _repository!.claimGiftCard(code);
        await refresh();
        return GiftCardRedeemResult.success;
      } catch (_) {
        return GiftCardRedeemResult.invalidCode;
      }
    }

    final normalized = code.toUpperCase();
    CustomerGiftCard? match;
    for (final card in _cards) {
      if (card.code.toUpperCase() == normalized) {
        match = card;
        break;
      }
    }
    if (match == null || match.status == GiftCardStatus.sent) {
      return GiftCardRedeemResult.invalidCode;
    }
    if (match.status == GiftCardStatus.redeemed) {
      return GiftCardRedeemResult.alreadyRedeemed;
    }
    final index = _cards.indexWhere((card) => card.id == match!.id);
    _cards[index] = match.copyWith(status: GiftCardStatus.redeemed);
    _balance += match.amount;
    await _saveDemo();
    notifyListeners();
    return GiftCardRedeemResult.success;
  }

  Future<double> spendBalance(double requestedAmount) async {
    if (usesApi) {
      return 0;
    }
    if (requestedAmount <= 0 || _balance <= 0) {
      return 0;
    }
    final applied = math.min(requestedAmount, _balance);
    _balance -= applied;
    if (_balance.abs() < 0.005) {
      _balance = 0;
    }
    await _saveDemo();
    notifyListeners();
    return applied;
  }

  Future<void> _loadDemo() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getDouble(_balanceKey) ?? 240;
    _cards
      ..clear()
      ..addAll(_decodeCards(prefs.getString(_recordsKey)));
    if (_cards.isEmpty) {
      _cards.addAll(_demoCards());
      await _saveDemo();
    }
    notifyListeners();
  }

  List<CustomerGiftCard> _decodeCards(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <CustomerGiftCard>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <CustomerGiftCard>[];
      }
      return decoded
          .whereType<Map>()
          .map((item) =>
              CustomerGiftCard.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return <CustomerGiftCard>[];
    }
  }

  List<CustomerGiftCard> _demoCards() {
    final now = DateTime.now();
    return <CustomerGiftCard>[
      CustomerGiftCard(
          id: 'demo-gift-received-100',
          code: 'GETIN100',
          amount: 100,
          currency: 'EGP',
          recipientName: 'Mohammed',
          recipientContact: 'demo@example.com',
          message: 'Coffee treat',
          deliveryDate: now,
          createdAt: now,
          status: GiftCardStatus.received),
    ];
  }

  Future<void> _saveDemo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, _balance);
    await prefs.setString(
        _recordsKey, jsonEncode(_cards.map((card) => card.toJson()).toList()));
  }

  Future<void> resetForTesting() async {
    if (usesApi) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_balanceKey);
    await prefs.remove(_recordsKey);
    _balance = 0;
    _cards.clear();
    notifyListeners();
  }
}
