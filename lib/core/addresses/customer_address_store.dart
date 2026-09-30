import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/customer_auth_store.dart';
import 'customer_address_repository.dart';

@immutable
class CustomerAddress {
  final String id;
  final String label;
  final String area;
  final String city;
  final String building;
  final String floor;
  final String apartment;
  final String deliveryInstructions;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const CustomerAddress({
    required this.id,
    required this.label,
    required this.area,
    required this.city,
    required this.building,
    required this.floor,
    required this.apartment,
    required this.deliveryInstructions,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  String get title => '$area, $city';

  String get details {
    final parts = <String>[
      if (building.trim().isNotEmpty) 'Building ${building.trim()}',
      if (floor.trim().isNotEmpty) 'Floor ${floor.trim()}',
      if (apartment.trim().isNotEmpty) 'Apt ${apartment.trim()}',
    ];
    return parts.join(' · ');
  }

  String get labelUpper => label.trim().toUpperCase();

  CustomerAddress copyWith({
    String? id,
    String? label,
    String? area,
    String? city,
    String? building,
    String? floor,
    String? apartment,
    String? deliveryInstructions,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      area: area ?? this.area,
      city: city ?? this.city,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      apartment: apartment ?? this.apartment,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'area': area,
        'city': city,
        'building': building,
        'floor': floor,
        'apartment': apartment,
        'deliveryInstructions': deliveryInstructions,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Home',
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? '',
      building: json['building'] as String? ?? '',
      floor: json['floor'] as String? ?? '',
      apartment: json['apartment'] as String? ?? '',
      deliveryInstructions: json['deliveryInstructions'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 31.2001,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 29.9187,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

class CustomerAddressStore extends ChangeNotifier {
  CustomerAddressStore._();

  static final CustomerAddressStore instance = CustomerAddressStore._();

  static const _addressesKey = 'getin_demo_saved_addresses_v1';
  static const _checkoutAddressKey = 'getin_demo_checkout_address_id_v1';

  final List<CustomerAddress> _addresses = <CustomerAddress>[];
  String? _checkoutAddressId;
  CustomerAddressRepository? _repository;

  bool get usesApi => _repository?.usesApi ?? false;

  List<CustomerAddress> get addresses => List.unmodifiable(_addresses);

  CustomerAddress? get defaultAddress {
    for (final address in _addresses) {
      if (address.isDefault) {
        return address;
      }
    }
    return _addresses.isEmpty ? null : _addresses.first;
  }

  CustomerAddress? get checkoutAddress {
    if (_checkoutAddressId != null) {
      for (final address in _addresses) {
        if (address.id == _checkoutAddressId) {
          return address;
        }
      }
    }
    return defaultAddress;
  }

  static Future<void> initialize({CustomerAddressRepository? repository}) async {
    instance._repository = repository;
    await instance._load();
  }

  Future<void> refreshFromApi() async {
    final repository = _repository;
    if (repository == null || !repository.usesApi ||
        !CustomerAuthStore.instance.isAuthenticated) {
      return;
    }
    final remote = await repository.list();
    _addresses
      ..clear()
      ..addAll(remote);
    _checkoutAddressId = defaultAddress?.id;
    await _persist();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressesKey);
    _addresses
      ..clear()
      ..addAll(_decodeAddresses(raw));

    if (_addresses.isEmpty && !usesApi) {
      _addresses.addAll(_demoAddresses());
      await _saveAddresses();
    }

    _checkoutAddressId = prefs.getString(_checkoutAddressKey);
    if (checkoutAddress == null && _addresses.isNotEmpty) {
      _checkoutAddressId = defaultAddress?.id ?? _addresses.first.id;
      await prefs.setString(_checkoutAddressKey, _checkoutAddressId!);
    }

    notifyListeners();
  }

  List<CustomerAddress> _decodeAddresses(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <CustomerAddress>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <CustomerAddress>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => CustomerAddress.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((address) => address.id.isNotEmpty)
          .toList();
    } catch (_) {
      return <CustomerAddress>[];
    }
  }

  List<CustomerAddress> _demoAddresses() => const <CustomerAddress>[
        CustomerAddress(
          id: 'demo-home-stanley',
          label: 'Home',
          area: 'Stanley',
          city: 'Alexandria',
          building: '12',
          floor: '4',
          apartment: '8',
          deliveryInstructions: 'Call on arrival',
          latitude: 31.23945,
          longitude: 29.96524,
          isDefault: true,
        ),
        CustomerAddress(
          id: 'demo-work-smouha',
          label: 'Work',
          area: 'Smouha',
          city: 'Alexandria',
          building: '14 · Business Center',
          floor: '',
          apartment: '',
          deliveryInstructions: 'Leave at reception',
          latitude: 31.21558,
          longitude: 29.94272,
          isDefault: false,
        ),
      ];

  Future<void> addAddress(CustomerAddress address) async {
    final repository = _repository;
    if (repository != null && repository.usesApi) {
      final account = CustomerAuthStore.instance.customer;
      if (account == null) return;
      final created = await repository.create(address, account: account);
      if (created.isDefault) _clearDefaultFlags();
      _addresses.add(created);
      _checkoutAddressId ??= created.id;
      if (created.isDefault) _checkoutAddressId = created.id;
      await _persist();
      return;
    }

    final shouldBeDefault = _addresses.isEmpty || address.isDefault;
    if (shouldBeDefault) _clearDefaultFlags();
    final normalized = address.copyWith(
      id: address.id.isEmpty
          ? 'address-${DateTime.now().microsecondsSinceEpoch}'
          : address.id,
      isDefault: shouldBeDefault,
    );
    _addresses.add(normalized);
    if (_checkoutAddressId == null || normalized.isDefault) {
      _checkoutAddressId = normalized.id;
    }
    await _persist();
  }

  Future<void> updateAddress(CustomerAddress updated) async {
    final index = _addresses.indexWhere((item) => item.id == updated.id);
    if (index < 0) return;
    final repository = _repository;
    if (repository != null && repository.usesApi) {
      final account = CustomerAuthStore.instance.customer;
      if (account == null) return;
      final remote = await repository.update(updated, account: account);
      if (remote.isDefault) _clearDefaultFlags();
      _addresses[index] = remote;
      await _persist();
      return;
    }
    if (updated.isDefault) _clearDefaultFlags();
    _addresses[index] = updated;
    if (!_addresses.any((item) => item.isDefault) && _addresses.isNotEmpty) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
    await _persist();
  }

  Future<void> deleteAddress(String id) async {
    final repository = _repository;
    if (repository != null && repository.usesApi) {
      await repository.delete(id);
    }
    final removed = _addresses.where((item) => item.id == id).toList();
    _addresses.removeWhere((item) => item.id == id);
    if (repository == null || !repository.usesApi) {
      if (removed.any((item) => item.isDefault) && _addresses.isNotEmpty) {
        _addresses[0] = _addresses[0].copyWith(isDefault: true);
      }
    }
    if (_checkoutAddressId == id) _checkoutAddressId = defaultAddress?.id;
    await _persist();
  }

  Future<void> setDefault(String id) async {
    final index = _addresses.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final repository = _repository;
    if (repository != null && repository.usesApi) {
      await repository.setDefault(id);
    }
    for (var i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(isDefault: i == index);
    }
    _checkoutAddressId = id;
    await _persist();
  }

  Future<void> selectForCheckout(String id) async {
    if (!_addresses.any((item) => item.id == id)) return;
    _checkoutAddressId = id;
    await _persist();
  }

  void _clearDefaultFlags() {
    for (var i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(isDefault: false);
    }
  }

  Future<void> _persist() async {
    await _saveAddresses();
    final prefs = await SharedPreferences.getInstance();
    if (_checkoutAddressId == null) {
      await prefs.remove(_checkoutAddressKey);
    } else {
      await prefs.setString(_checkoutAddressKey, _checkoutAddressId!);
    }
    notifyListeners();
  }

  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _addresses.map((address) => address.toJson()).toList(),
    );
    await prefs.setString(_addressesKey, encoded);
  }

  @visibleForTesting
  Future<void> resetForTesting({bool seedDemoAddresses = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_addressesKey);
    await prefs.remove(_checkoutAddressKey);
    _addresses
      ..clear()
      ..addAll(
          seedDemoAddresses ? _demoAddresses() : const <CustomerAddress>[]);
    _checkoutAddressId = defaultAddress?.id;
    if (seedDemoAddresses) {
      await _persist();
    } else {
      notifyListeners();
    }
  }
}
