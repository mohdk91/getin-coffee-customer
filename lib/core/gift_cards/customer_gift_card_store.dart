import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/customer_repository.dart';
import '../engagement/customer_engagement_api_repository.dart';

enum GiftCardStatus { sent, received, redeemed }

enum GiftCardRedeemResult { success, invalidCode, alreadyRedeemed }

@immutable
class CustomerGiftCardTransaction {
  final String id;
  final String type;
  final double amount;
  final double balanceAfter;
  final String? reference;
  final String? description;
  final DateTime? createdAt;

  const CustomerGiftCardTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.reference,
    required this.description,
    required this.createdAt,
  });

  factory CustomerGiftCardTransaction.fromApi(Map<String, dynamic> json) =>
      CustomerGiftCardTransaction(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
        balanceAfter:
            double.tryParse(json['balance_after']?.toString() ?? '') ?? 0,
        reference: json['reference']?.toString(),
        description: json['description']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

@immutable
class CustomerGiftCard {
  final String id;
  final String code;
  final double amount;
  final double currentBalance;
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
    required this.currentBalance,
    required this.currency,
    required this.recipientName,
    required this.recipientContact,
    required this.message,
    required this.deliveryDate,
    required this.createdAt,
    required this.status,
  });

  bool get canSpend =>
      status == GiftCardStatus.received && currentBalance > 0.004;

  CustomerGiftCard copyWith({
    GiftCardStatus? status,
    double? currentBalance,
  }) =>
      CustomerGiftCard(
        id: id,
        code: code,
        amount: amount,
        currentBalance: currentBalance ?? this.currentBalance,
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
        'currentBalance': currentBalance,
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
    final amount = (json['amount'] as num?)?.toDouble() ?? 0;
    return CustomerGiftCard(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      amount: amount,
      currentBalance:
          (json['currentBalance'] as num?)?.toDouble() ?? amount,
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
  final Map<String, List<CustomerGiftCardTransaction>> _transactionsByCard =
      <String, List<CustomerGiftCardTransaction>>{};
  String? _checkoutCardId;

  bool get usesApi => _repository?.usesApi ?? false;
  double get balance => _balance;
  List<CustomerGiftCard> get cards => List.unmodifiable(_cards);
  String? get checkoutCardId => _checkoutCardId;
  CustomerGiftCard? get checkoutCard {
    final id = _checkoutCardId;
    if (id == null) return null;
    for (final card in _cards) {
      if (card.id == id && card.canSpend) return card;
    }
    return null;
  }

  List<CustomerGiftCard> get sentCards => _cards
      .where((card) => card.status == GiftCardStatus.sent)
      .toList(growable: false);
  List<CustomerGiftCard> get receivedCards =>
      _cards.where((card) => card.canSpend).toList(growable: false);
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
        .where((card) => card.canSpend)
        .fold<double>(0, (sum, card) => sum + card.currentBalance);
    _transactionsByCard.removeWhere(
      (id, _) => !_cards.any((card) => card.id == id),
    );
    if (checkoutCard == null) {
      _checkoutCardId = null;
    }
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
      currentBalance: balance,
      currency: json['currency']?.toString() ?? 'EGP',
      recipientName: json['recipient_name']?.toString() ?? 'GETIN Customer',
      recipientContact: '',
      message: 'Server-managed GETIN gift card',
      deliveryDate: issued,
      createdAt: issued,
      status: status,
    );
  }

  Future<void> selectForCheckout(String? cardId) async {
    if (cardId == null) {
      _checkoutCardId = null;
      notifyListeners();
      return;
    }
    final card = _cards.where((item) => item.id == cardId).firstOrNull;
    if (card == null || !card.canSpend) {
      throw StateError('This gift card is not available for checkout.');
    }
    _checkoutCardId = card.id;
    notifyListeners();
  }

  List<CustomerGiftCardTransaction> transactionsFor(String cardId) =>
      List.unmodifiable(
        _transactionsByCard[cardId] ?? const <CustomerGiftCardTransaction>[],
      );

  Future<List<CustomerGiftCardTransaction>> refreshTransactions(
    String cardId,
  ) async {
    final repository = _repository;
    final numericId = int.tryParse(cardId);
    if (repository == null || !repository.usesApi || numericId == null) {
      return transactionsFor(cardId);
    }
    final raw = await repository.giftCardTransactions(numericId);
    final items = raw
        .map(CustomerGiftCardTransaction.fromApi)
        .toList(growable: false);
    _transactionsByCard[cardId] = items;
    notifyListeners();
    return List.unmodifiable(items);
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
      currentBalance: amount,
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
    // Demo mode keeps its original aggregate wallet behavior. Live/API mode
    // never reaches this path and always spends a specific server card.
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
        currentBalance: 100,
        currency: 'EGP',
        recipientName: 'Mohammed',
        recipientContact: 'demo@example.com',
        message: 'Coffee treat',
        deliveryDate: now,
        createdAt: now,
        status: GiftCardStatus.received,
      ),
    ];
  }

  Future<void> _saveDemo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, _balance);
    await prefs.setString(
      _recordsKey,
      jsonEncode(_cards.map((card) => card.toJson()).toList()),
    );
  }

  Future<void> resetForTesting() async {
    if (usesApi) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_balanceKey);
    await prefs.remove(_recordsKey);
    _balance = 0;
    _checkoutCardId = null;
    _cards.clear();
    _transactionsByCard.clear();
    notifyListeners();
  }
}

extension _FirstOrNullGiftCard on Iterable<CustomerGiftCard> {
  CustomerGiftCard? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
