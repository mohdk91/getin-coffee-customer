import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'customer_favorites_repository.dart';

class FavoriteProductEntry {
  final String id;
  final int? serverProductId;
  final String name;
  final String description;
  final String image;
  final String price;
  final String branchName;
  final String serviceType;

  const FavoriteProductEntry({
    required this.id,
    this.serverProductId,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.branchName,
    required this.serviceType,
  });

  factory FavoriteProductEntry.fromProduct({
    int? serverProductId,
    required String name,
    required String description,
    required String image,
    required String price,
    required String branchName,
    required String serviceType,
  }) {
    return FavoriteProductEntry(
      id: CustomerFavoritesStore.productId(name),
      serverProductId: serverProductId,
      name: name,
      description: description,
      image: image,
      price: price,
      branchName: branchName,
      serviceType: serviceType,
    );
  }

  factory FavoriteProductEntry.fromJson(Map<String, dynamic> json) {
    return FavoriteProductEntry(
      id: json['id'] as String? ?? '',
      serverProductId: (json['serverProductId'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      image: json['image'] as String? ?? '',
      price: json['price'] as String? ?? '',
      branchName: json['branchName'] as String? ?? 'Getin Stanley',
      serviceType: json['serviceType'] as String? ?? 'delivery',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'serverProductId': serverProductId,
        'name': name,
        'description': description,
        'image': image,
        'price': price,
        'branchName': branchName,
        'serviceType': serviceType,
      };
}

class CustomerFavoritesStore extends ChangeNotifier {
  CustomerFavoritesStore._();

  static final CustomerFavoritesStore instance = CustomerFavoritesStore._();
  static const String _storageKey = 'getin_demo_favorite_products_v1';

  final List<FavoriteProductEntry> _products = <FavoriteProductEntry>[];
  bool _initialized = false;
  CustomerFavoritesRepository? _repository;

  List<FavoriteProductEntry> get products => List.unmodifiable(_products);
  int get count => _products.length;
  bool get isEmpty => _products.isEmpty;

  static String productId(String name) {
    final normalized =
        name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return Uri.encodeComponent(normalized);
  }

  static Future<void> initialize({CustomerFavoritesRepository? repository}) {
    instance._repository = repository;
    return instance._initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _products
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map(
                (item) => FavoriteProductEntry.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.id.isNotEmpty && item.name.isNotEmpty),
        );
    } catch (_) {
      // Demo storage should never prevent the app from starting.
      _products.clear();
    }
  }

  bool containsName(String name) => containsId(productId(name));

  bool containsId(String id) => _products.any((product) => product.id == id);

  FavoriteProductEntry? findByName(String name) {
    final id = productId(name);
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<bool> toggle(FavoriteProductEntry product) async {
    final existingIndex = _products.indexWhere((item) => item.id == product.id);
    final added = existingIndex == -1;

    if (added) {
      _products.insert(0, product);
    } else {
      _products.removeAt(existingIndex);
    }

    notifyListeners();
    await _persist();

    final serverId = product.serverProductId;
    final repository = _repository;
    if (serverId != null && repository != null && repository.usesApi) {
      try {
        if (added) {
          await repository.add(serverId);
        } else {
          await repository.remove(serverId);
        }
      } catch (_) {
        // Keep optimistic local UI; next authenticated refresh reconciles state.
      }
    }
    return added;
  }

  Future<void> removeById(String id) async {
    final before = _products.length;
    _products.removeWhere((product) => product.id == id);
    if (_products.length == before) return;
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    if (_products.isEmpty) return;
    _products.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_products.map((product) => product.toJson()).toList()),
    );
  }

  @visibleForTesting
  Future<void> resetForTests() async {
    _products.clear();
    _initialized = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}
