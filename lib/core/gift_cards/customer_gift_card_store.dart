import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  CustomerGiftCard copyWith({GiftCardStatus? status}) {
    return CustomerGiftCard(
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
  }

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
    final rawStatus = json['status'] as String? ?? GiftCardStatus.received.name;
    final status = GiftCardStatus.values.firstWhere(
      (value) => value.name == rawStatus,
      orElse: () => GiftCardStatus.received,
    );
    return CustomerGiftCard(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'EGP',
      recipientName: json['recipientName'] as String? ?? '',
      recipientContact: json['recipientContact'] as String? ?? '',
      message: json['message'] as String? ?? '',
      deliveryDate: DateTime.tryParse(json['deliveryDate'] as String? ?? '') ??
          DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
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

  double _balance = 0;
  final List<CustomerGiftCard> _cards = <CustomerGiftCard>[];

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

  static Future<void> initialize() async {
    await instance._load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawBalance = prefs.getDouble(_balanceKey);
    final rawCards = prefs.getString(_recordsKey);

    _balance = rawBalance ?? 240;
    _cards
      ..clear()
      ..addAll(_decodeCards(rawCards));

    if (_cards.isEmpty) {
      _cards.addAll(_demoCards());
      await _save();
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
          .map(
            (item) => CustomerGiftCard.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((card) => card.id.isNotEmpty && card.code.isNotEmpty)
          .toList();
    } catch (_) {
      return <CustomerGiftCard>[];
    }
  }

  List<CustomerGiftCard> _demoCards() {
    final now = DateTime.now();
    return <CustomerGiftCard>[
      CustomerGiftCard(
        id: 'demo-gift-sent-250',
        code: 'GETIN-SENT-250',
        amount: 250,
        currency: 'EGP',
        recipientName: 'Mariam',
        recipientContact: 'mariam@example.com',
        message: 'Coffee is on me.',
        deliveryDate: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 1)),
        status: GiftCardStatus.sent,
      ),
      CustomerGiftCard(
        id: 'demo-gift-received-100',
        code: 'GETIN100',
        amount: 100,
        currency: 'EGP',
        recipientName: 'Mohammed',
        recipientContact: 'mohammed@example.com',
        message: 'A little coffee treat for you.',
        deliveryDate: now,
        createdAt: now.subtract(const Duration(hours: 8)),
        status: GiftCardStatus.received,
      ),
      CustomerGiftCard(
        id: 'demo-gift-redeemed-240',
        code: 'GETIN-REDEEMED-240',
        amount: 240,
        currency: 'EGP',
        recipientName: 'Mohammed',
        recipientContact: 'mohammed@example.com',
        message: 'Already added to Gift Card Balance.',
        deliveryDate: now.subtract(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 10)),
        status: GiftCardStatus.redeemed,
      ),
    ];
  }

  Future<CustomerGiftCard> purchase({
    required double amount,
    required String recipientName,
    required String recipientContact,
    required String message,
    required DateTime deliveryDate,
    String currency = 'EGP',
  }) async {
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
    await _save();
    notifyListeners();
    return card;
  }

  Future<GiftCardRedeemResult> redeemCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    CustomerGiftCard? match;
    for (final card in _cards) {
      if (card.code.toUpperCase() == code) {
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
    await _save();
    notifyListeners();
    return GiftCardRedeemResult.success;
  }

  Future<double> spendBalance(double requestedAmount) async {
    if (requestedAmount <= 0 || _balance <= 0) {
      return 0;
    }
    final applied = math.min(requestedAmount, _balance);
    _balance -= applied;
    if (_balance.abs() < 0.005) {
      _balance = 0;
    }
    await _save();
    notifyListeners();
    return applied;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, _balance);
    await prefs.setString(
      _recordsKey,
      jsonEncode(_cards.map((card) => card.toJson()).toList()),
    );
  }

  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_balanceKey);
    await prefs.remove(_recordsKey);
    _balance = 0;
    _cards.clear();
    notifyListeners();
  }
}
