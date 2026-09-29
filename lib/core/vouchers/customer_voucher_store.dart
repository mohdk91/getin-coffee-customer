import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VoucherStatus {
  available,
  applied,
  used,
  expired,
}

class CustomerVoucher {
  final String id;
  final String code;
  final String title;
  final String description;
  final double discountAmount;
  final double minimumSpend;
  final DateTime expiresAt;
  final String terms;
  final VoucherStatus status;
  final DateTime? usedAt;

  const CustomerVoucher({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.minimumSpend,
    required this.expiresAt,
    required this.terms,
    required this.status,
    this.usedAt,
  });

  CustomerVoucher copyWith({
    VoucherStatus? status,
    DateTime? usedAt,
    bool clearUsedAt = false,
  }) {
    return CustomerVoucher(
      id: id,
      code: code,
      title: title,
      description: description,
      discountAmount: discountAmount,
      minimumSpend: minimumSpend,
      expiresAt: expiresAt,
      terms: terms,
      status: status ?? this.status,
      usedAt: clearUsedAt ? null : usedAt ?? this.usedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'discountAmount': discountAmount,
      'minimumSpend': minimumSpend,
      'expiresAt': expiresAt.toIso8601String(),
      'terms': terms,
      'status': status.name,
      'usedAt': usedAt?.toIso8601String(),
    };
  }

  static CustomerVoucher? fromJson(Map<String, Object?> json) {
    final id = json['id'] as String?;
    final code = json['code'] as String?;
    final title = json['title'] as String?;
    final description = json['description'] as String?;
    final expiresAt = DateTime.tryParse(json['expiresAt'] as String? ?? '');
    final terms = json['terms'] as String?;
    final statusName = json['status'] as String?;

    final discountRaw = json['discountAmount'];
    final minimumRaw = json['minimumSpend'];
    final discountAmount = discountRaw is num ? discountRaw.toDouble() : null;
    final minimumSpend = minimumRaw is num ? minimumRaw.toDouble() : null;

    if (id == null ||
        code == null ||
        title == null ||
        description == null ||
        discountAmount == null ||
        minimumSpend == null ||
        expiresAt == null ||
        terms == null ||
        statusName == null) {
      return null;
    }

    final statuses = VoucherStatus.values.where(
      (value) => value.name == statusName,
    );
    if (statuses.isEmpty) {
      return null;
    }

    return CustomerVoucher(
      id: id,
      code: code,
      title: title,
      description: description,
      discountAmount: discountAmount,
      minimumSpend: minimumSpend,
      expiresAt: expiresAt,
      terms: terms,
      status: statuses.first,
      usedAt: DateTime.tryParse(json['usedAt'] as String? ?? ''),
    );
  }
}

class CustomerVoucherStore extends ChangeNotifier {
  CustomerVoucherStore._();

  static final CustomerVoucherStore instance = CustomerVoucherStore._();

  static const String _storageKey = 'getin_demo_vouchers_v1';

  SharedPreferences? _preferences;
  List<CustomerVoucher> _vouchers = <CustomerVoucher>[];

  List<CustomerVoucher> get vouchers => List.unmodifiable(_vouchers);

  List<CustomerVoucher> get availableVouchers => _vouchers
      .where(
        (voucher) => voucher.status == VoucherStatus.available,
      )
      .toList(growable: false);

  List<CustomerVoucher> get appliedVouchers => _vouchers
      .where(
        (voucher) => voucher.status == VoucherStatus.applied,
      )
      .toList(growable: false);

  List<CustomerVoucher> get usedVouchers => _vouchers
      .where(
        (voucher) => voucher.status == VoucherStatus.used,
      )
      .toList(growable: false);

  List<CustomerVoucher> get expiredVouchers => _vouchers
      .where(
        (voucher) => voucher.status == VoucherStatus.expired,
      )
      .toList(growable: false);

  int get availableCount => availableVouchers.length;

  static Future<void> initialize() async {
    final store = instance;
    store._preferences = await SharedPreferences.getInstance();
    store._load();
  }

  CustomerVoucher? voucherById(String id) {
    for (final voucher in _vouchers) {
      if (voucher.id == id) {
        return voucher;
      }
    }
    return null;
  }

  CustomerVoucher? voucherByCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final voucher in _vouchers) {
      if (voucher.code.toUpperCase() == normalized) {
        return voucher;
      }
    }
    return null;
  }

  void markApplied(String id) {
    _updateStatus(id, VoucherStatus.applied);
  }

  void markAvailable(String id) {
    final voucher = voucherById(id);
    if (voucher == null ||
        voucher.status == VoucherStatus.used ||
        voucher.status == VoucherStatus.expired) {
      return;
    }
    _updateStatus(id, VoucherStatus.available, clearUsedAt: true);
  }

  void markUsed(String id) {
    final index = _vouchers.indexWhere((voucher) => voucher.id == id);
    if (index == -1) {
      return;
    }

    _vouchers[index] = _vouchers[index].copyWith(
      status: VoucherStatus.used,
      usedAt: DateTime.now(),
    );
    _changed();
  }

  void resetToDemoDefaults({
    bool persist = false,
  }) {
    _setDemoDefaults();
    notifyListeners();
    if (persist) {
      unawaited(_persist());
    }
  }

  void _load() {
    final raw = _preferences?.getString(_storageKey);
    final decoded = _decode(raw);

    if (decoded.isEmpty) {
      _setDemoDefaults();
      unawaited(_persist());
      notifyListeners();
      return;
    }

    _vouchers = decoded.map((voucher) {
      if (voucher.status == VoucherStatus.applied) {
        return voucher.copyWith(status: VoucherStatus.available);
      }
      if (voucher.status != VoucherStatus.used &&
          voucher.expiresAt.isBefore(DateTime.now())) {
        return voucher.copyWith(status: VoucherStatus.expired);
      }
      return voucher;
    }).toList(growable: false);

    notifyListeners();
  }

  void _setDemoDefaults() {
    final now = DateTime.now();
    _vouchers = <CustomerVoucher>[
      CustomerVoucher(
        id: 'demo-getin20',
        code: 'GETIN20',
        title: 'EGP 20 OFF',
        description: 'Save EGP 20 on an eligible Getin order.',
        discountAmount: 20,
        minimumSpend: 60,
        expiresAt: now.add(const Duration(days: 30)),
        terms:
            'Valid once on eligible products. Minimum product subtotal EGP 60. Delivery and service fees do not count toward minimum spend.',
        status: VoucherStatus.available,
      ),
      CustomerVoucher(
        id: 'demo-getin50',
        code: 'GETIN50',
        title: 'EGP 50 OFF',
        description: 'Save EGP 50 when your product subtotal reaches EGP 250.',
        discountAmount: 50,
        minimumSpend: 250,
        expiresAt: now.add(const Duration(days: 45)),
        terms:
            'Valid once on eligible products. Minimum product subtotal EGP 250. Cannot reduce the product subtotal below zero.',
        status: VoucherStatus.available,
      ),
      CustomerVoucher(
        id: 'demo-welcome10-used',
        code: 'WELCOME10',
        title: 'EGP 10 OFF',
        description: 'Welcome voucher used on a previous demo order.',
        discountAmount: 10,
        minimumSpend: 50,
        expiresAt: now.add(const Duration(days: 20)),
        terms: 'Single-use welcome voucher.',
        status: VoucherStatus.used,
        usedAt: now.subtract(const Duration(days: 8)),
      ),
      CustomerVoucher(
        id: 'demo-fall15-expired',
        code: 'FALL15',
        title: 'EGP 15 OFF',
        description: 'Seasonal voucher that has expired.',
        discountAmount: 15,
        minimumSpend: 80,
        expiresAt: now.subtract(const Duration(days: 5)),
        terms: 'This seasonal voucher is no longer valid.',
        status: VoucherStatus.expired,
      ),
    ];
  }

  void _updateStatus(
    String id,
    VoucherStatus status, {
    bool clearUsedAt = false,
  }) {
    final index = _vouchers.indexWhere((voucher) => voucher.id == id);
    if (index == -1) {
      return;
    }

    _vouchers[index] = _vouchers[index].copyWith(
      status: status,
      clearUsedAt: clearUsedAt,
    );
    _changed();
  }

  void _changed() {
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    await preferences.setString(
      _storageKey,
      jsonEncode(
        _vouchers.map((voucher) => voucher.toJson()).toList(),
      ),
    );
  }

  static List<CustomerVoucher> _decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <CustomerVoucher>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <CustomerVoucher>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => CustomerVoucher.fromJson(
              item.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            ),
          )
          .whereType<CustomerVoucher>()
          .toList(growable: false);
    } catch (_) {
      return <CustomerVoucher>[];
    }
  }
}
