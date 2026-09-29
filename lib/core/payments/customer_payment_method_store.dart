import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class CustomerPaymentMethod {
  final String id;
  final String providerTokenRef;
  final String brand;
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;

  const CustomerPaymentMethod({
    required this.id,
    required this.providerTokenRef,
    required this.brand,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.isDefault,
  });

  String get normalizedBrand => brand.trim().toUpperCase();

  String get maskedLabel => '$normalizedBrand •••• $last4';

  String get expiryLabel =>
      '${expiryMonth.toString().padLeft(2, '0')}/${(expiryYear % 100).toString().padLeft(2, '0')}';

  bool isExpiredAt(DateTime now) {
    if (expiryYear < now.year) {
      return true;
    }
    return expiryYear == now.year && expiryMonth < now.month;
  }

  bool get isExpired => isExpiredAt(DateTime.now());

  CustomerPaymentMethod copyWith({
    String? id,
    String? providerTokenRef,
    String? brand,
    String? last4,
    int? expiryMonth,
    int? expiryYear,
    bool? isDefault,
  }) {
    return CustomerPaymentMethod(
      id: id ?? this.id,
      providerTokenRef: providerTokenRef ?? this.providerTokenRef,
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'providerTokenRef': providerTokenRef,
        'brand': brand,
        'last4': last4,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'isDefault': isDefault,
      };

  factory CustomerPaymentMethod.fromJson(Map<String, dynamic> json) {
    return CustomerPaymentMethod(
      id: json['id'] as String? ?? '',
      providerTokenRef: json['providerTokenRef'] as String? ?? '',
      brand: json['brand'] as String? ?? 'CARD',
      last4: json['last4'] as String? ?? '0000',
      expiryMonth: (json['expiryMonth'] as num?)?.toInt() ?? 1,
      expiryYear: (json['expiryYear'] as num?)?.toInt() ?? 2000,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

class CustomerPaymentMethodStore extends ChangeNotifier {
  CustomerPaymentMethodStore._();

  static final CustomerPaymentMethodStore instance =
      CustomerPaymentMethodStore._();

  static const _methodsKey = 'getin_demo_payment_methods_v1';
  static const _checkoutMethodKey = 'getin_demo_checkout_payment_method_v1';

  final List<CustomerPaymentMethod> _methods = <CustomerPaymentMethod>[];
  String? _checkoutMethodId;

  List<CustomerPaymentMethod> get methods => List.unmodifiable(_methods);

  List<CustomerPaymentMethod> get activeMethods =>
      _methods.where((method) => !method.isExpired).toList(growable: false);

  CustomerPaymentMethod? get defaultMethod {
    for (final method in _methods) {
      if (method.isDefault && !method.isExpired) {
        return method;
      }
    }
    for (final method in _methods) {
      if (!method.isExpired) {
        return method;
      }
    }
    return null;
  }

  CustomerPaymentMethod? get checkoutMethod {
    final selected = methodById(_checkoutMethodId);
    if (selected != null && !selected.isExpired) {
      return selected;
    }
    return defaultMethod;
  }

  CustomerPaymentMethod? methodById(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final method in _methods) {
      if (method.id == id) {
        return method;
      }
    }
    return null;
  }

  static Future<void> initialize() async {
    await instance._load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_methodsKey);
    _methods
      ..clear()
      ..addAll(_decodeMethods(raw));

    if (_methods.isEmpty) {
      _methods.addAll(_demoMethods());
      await _saveMethods();
    }

    _normalizeDefault();
    _checkoutMethodId = prefs.getString(_checkoutMethodKey);
    if (checkoutMethod == null && defaultMethod != null) {
      _checkoutMethodId = defaultMethod!.id;
    }
    await _saveAll();
    notifyListeners();
  }

  List<CustomerPaymentMethod> _decodeMethods(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <CustomerPaymentMethod>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <CustomerPaymentMethod>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => CustomerPaymentMethod.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (method) =>
                method.id.isNotEmpty &&
                method.providerTokenRef.isNotEmpty &&
                RegExp(r'^\d{4}$').hasMatch(method.last4),
          )
          .toList();
    } catch (_) {
      return <CustomerPaymentMethod>[];
    }
  }

  List<CustomerPaymentMethod> _demoMethods() => const <CustomerPaymentMethod>[
        CustomerPaymentMethod(
          id: 'demo-card-visa-5008',
          providerTokenRef: 'demo_pm_visa_5008',
          brand: 'VISA',
          last4: '5008',
          expiryMonth: 7,
          expiryYear: 2029,
          isDefault: true,
        ),
        CustomerPaymentMethod(
          id: 'demo-card-mastercard-1192',
          providerTokenRef: 'demo_pm_mastercard_1192',
          brand: 'MASTERCARD',
          last4: '1192',
          expiryMonth: 11,
          expiryYear: 2028,
          isDefault: false,
        ),
        CustomerPaymentMethod(
          id: 'demo-card-visa-expired-0441',
          providerTokenRef: 'demo_pm_visa_0441_expired',
          brand: 'VISA',
          last4: '0441',
          expiryMonth: 4,
          expiryYear: 2025,
          isDefault: false,
        ),
      ];

  Future<CustomerPaymentMethod> addDemoTokenizedCard({
    required String brand,
    required String last4,
    required int expiryMonth,
    required int expiryYear,
    bool makeDefault = false,
  }) async {
    final normalizedLast4 = last4.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(normalizedLast4)) {
      throw ArgumentError('Last four digits must contain exactly 4 digits.');
    }
    if (expiryMonth < 1 || expiryMonth > 12) {
      throw ArgumentError('Expiry month is invalid.');
    }

    final preview = CustomerPaymentMethod(
      id: 'preview',
      providerTokenRef: 'preview',
      brand: brand,
      last4: normalizedLast4,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: false,
    );
    if (preview.isExpired) {
      throw ArgumentError('Expired cards cannot be added.');
    }

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final method = CustomerPaymentMethod(
      id: 'demo-card-$stamp',
      providerTokenRef: 'demo_pm_$stamp',
      brand: brand.trim().toUpperCase(),
      last4: normalizedLast4,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: makeDefault || defaultMethod == null,
    );

    if (method.isDefault) {
      _clearDefaultFlags();
    }
    _methods.add(method);
    if (_checkoutMethodId == null || method.isDefault) {
      _checkoutMethodId = method.id;
    }
    await _saveAll();
    notifyListeners();
    return method;
  }

  Future<bool> setDefault(String id) async {
    final method = methodById(id);
    if (method == null || method.isExpired) {
      return false;
    }

    _clearDefaultFlags();
    final index = _methods.indexWhere((item) => item.id == id);
    _methods[index] = _methods[index].copyWith(isDefault: true);
    _checkoutMethodId ??= id;
    await _saveAll();
    notifyListeners();
    return true;
  }

  Future<bool> selectForCheckout(String id) async {
    final method = methodById(id);
    if (method == null || method.isExpired) {
      return false;
    }
    _checkoutMethodId = id;
    await _saveCheckoutMethod();
    notifyListeners();
    return true;
  }

  Future<void> remove(String id) async {
    final removed = methodById(id);
    if (removed == null) {
      return;
    }

    _methods.removeWhere((method) => method.id == id);
    if (_checkoutMethodId == id) {
      _checkoutMethodId = null;
    }

    if (removed.isDefault) {
      _normalizeDefault();
    }
    if (_checkoutMethodId == null && defaultMethod != null) {
      _checkoutMethodId = defaultMethod!.id;
    }

    await _saveAll();
    notifyListeners();
  }

  void _clearDefaultFlags() {
    for (var index = 0; index < _methods.length; index++) {
      if (_methods[index].isDefault) {
        _methods[index] = _methods[index].copyWith(isDefault: false);
      }
    }
  }

  void _normalizeDefault() {
    final active = _methods.where((method) => !method.isExpired).toList();
    if (active.isEmpty) {
      _clearDefaultFlags();
      return;
    }

    final validDefaults = active.where((method) => method.isDefault).toList();
    final keepId =
        validDefaults.isNotEmpty ? validDefaults.first.id : active.first.id;

    for (var index = 0; index < _methods.length; index++) {
      _methods[index] = _methods[index].copyWith(
        isDefault: _methods[index].id == keepId,
      );
    }
  }

  Future<void> _saveAll() async {
    await _saveMethods();
    await _saveCheckoutMethod();
  }

  Future<void> _saveMethods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _methodsKey,
      jsonEncode(_methods.map((method) => method.toJson()).toList()),
    );
  }

  Future<void> _saveCheckoutMethod() async {
    final prefs = await SharedPreferences.getInstance();
    if (_checkoutMethodId == null) {
      await prefs.remove(_checkoutMethodKey);
      return;
    }
    await prefs.setString(_checkoutMethodKey, _checkoutMethodId!);
  }

  Future<void> resetForTesting() async {
    _methods.clear();
    _checkoutMethodId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_methodsKey);
    await prefs.remove(_checkoutMethodKey);
    notifyListeners();
  }
}
