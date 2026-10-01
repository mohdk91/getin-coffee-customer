import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/customer_repository.dart';
import '../engagement/customer_engagement_api_repository.dart';

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
  final String discountType;
  final double discountValue;
  final String? currency;
  final double? maximumDiscount;
  final bool serverManaged;

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
    this.discountType = 'fixed',
    this.discountValue = 0,
    this.currency,
    this.maximumDiscount,
    this.serverManaged = false,
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
      discountType: discountType,
      discountValue: discountValue,
      currency: currency,
      maximumDiscount: maximumDiscount,
      serverManaged: serverManaged,
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
      'discountType': discountType,
      'discountValue': discountValue,
      'currency': currency,
      'maximumDiscount': maximumDiscount,
      'serverManaged': serverManaged,
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
      discountType: json['discountType']?.toString() ?? 'fixed',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? discountAmount,
      currency: json['currency']?.toString(),
      maximumDiscount: (json['maximumDiscount'] as num?)?.toDouble(),
      serverManaged: json['serverManaged'] == true,
    );
  }
}

class CustomerVoucherStore extends ChangeNotifier {
  CustomerVoucherStore._();

  static final CustomerVoucherStore instance = CustomerVoucherStore._();

  static const String _storageKey = 'getin_demo_vouchers_v1';

  SharedPreferences? _preferences;
  CustomerEngagementApiRepository? _repository;
  List<CustomerVoucher> _vouchers = <CustomerVoucher>[];

  bool get usesApi => _repository?.usesApi ?? false;
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

  static Future<void> initialize([CustomerRepositoryContext? context]) async {
    final store = instance;
    if (context != null) {
      store._repository = CustomerEngagementApiRepository(context);
    }
    if (store.usesApi) {
      store._preferences = null;
      await store.refresh();
      return;
    }
    store._preferences = await SharedPreferences.getInstance();
    store._load();
  }

  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null || !repository.usesApi) {
      return;
    }
    final items = await repository.vouchers();
    _vouchers = items.map(_fromApi).toList(growable: false);
    notifyListeners();
  }

  Future<String?> validateLiveVoucher(String id) async {
    final repository = _repository;
    if (repository == null || !repository.usesApi) {
      return null;
    }
    final voucherId = int.tryParse(id);
    if (voucherId == null || voucherId <= 0) {
      return 'voucher_id_invalid';
    }
    final result = await repository.validateVoucher(voucherId);
    if (result['valid'] == true) {
      return null;
    }
    return result['reason']?.toString() ?? 'voucher_invalid';
  }

  CustomerVoucher _fromApi(Map<String, dynamic> json) {
    final template = json['template'] is Map
        ? Map<String, dynamic>.from(json['template'] as Map)
        : const <String, dynamic>{};
    final rawStatus = json['status']?.toString().toLowerCase() ?? '';
    final status = switch (rawStatus) {
      'redeemed' || 'used' => VoucherStatus.used,
      'expired' => VoucherStatus.expired,
      _ => VoucherStatus.available,
    };
    final discountType = template['discount_type']?.toString() ?? 'fixed';
    final value = double.tryParse(template['value']?.toString() ?? '') ?? 0;
    final minimumSpend =
        double.tryParse(template['minimum_order_amount']?.toString() ?? '') ?? 0;
    final maximumDiscount =
        double.tryParse(template['maximum_discount_amount']?.toString() ?? '');
    final expiresAt = DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
        DateTime.tryParse(template['ends_at']?.toString() ?? '') ??
        DateTime.now().add(const Duration(days: 3650));
    final currency = template['currency']?.toString();
    final discountAmount = discountType == 'fixed' ? value : 0.0;

    return CustomerVoucher(
      id: json['id']?.toString() ?? '',
      code: json['voucher_code']?.toString() ?? '',
      title: template['name']?.toString() ?? 'GETIN Voucher',
      description: template['description']?.toString() ?? '',
      discountAmount: discountAmount,
      minimumSpend: minimumSpend,
      expiresAt: expiresAt,
      terms: 'Server-managed voucher. Final eligibility and saving are confirmed by Laravel at checkout.',
      status: status,
      usedAt: DateTime.tryParse(json['redeemed_at']?.toString() ?? ''),
      discountType: discountType,
      discountValue: value,
      currency: currency,
      maximumDiscount: maximumDiscount,
      serverManaged: true,
    );
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
    if (usesApi) {
      return;
    }
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
    if (usesApi) {
      return;
    }
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
        discountValue: 20,
        currency: 'EGP',
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
        discountValue: 50,
        currency: 'EGP',
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
        discountValue: 10,
        currency: 'EGP',
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
        discountValue: 15,
        currency: 'EGP',
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
    if (!usesApi) {
      unawaited(_persist());
    }
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null || usesApi) {
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
