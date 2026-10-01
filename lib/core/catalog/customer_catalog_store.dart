import 'package:flutter/foundation.dart';

import '../data/customer_repository.dart';
import '../../features/location/models/branch.dart';
import 'customer_catalog_models.dart';
import 'customer_catalog_repository.dart';

class CustomerCatalogStore extends ChangeNotifier {
  CustomerCatalogStore._();

  static final CustomerCatalogStore instance = CustomerCatalogStore._();

  CustomerCatalogRepository? _repository;
  final List<Branch> _branches = <Branch>[];
  final Map<int, List<CatalogCategory>> _categoriesByBranch =
      <int, List<CatalogCategory>>{};
  final Map<int, List<CatalogProduct>> _productsByBranch =
      <int, List<CatalogProduct>>{};
  bool _loading = false;
  Object? _lastError;

  List<Branch> get branches => List<Branch>.unmodifiable(_branches);
  bool get loading => _loading;
  Object? get lastError => _lastError;
  bool get usesApi => _repository?.context.usesApi ?? false;

  List<CatalogCategory> get categories {
    if (_categoriesByBranch.isEmpty) return const <CatalogCategory>[];
    return List<CatalogCategory>.unmodifiable(_categoriesByBranch.values.first);
  }

  static Future<void> initialize(CustomerRepositoryContext context) async {
    instance._repository = CustomerCatalogRepository(context);
    if (!context.usesApi) return;
    await instance.refreshBranches();
    if (instance._branches.isNotEmpty) {
      await instance.refreshBranch(instance._branches.first.id);
    }
  }

  Future<void> refreshBranches({String? service}) async {
    final repository = _repository;
    if (repository == null) return;
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      final rows = await repository.branches(service: service);
      _branches
        ..clear()
        ..addAll(rows);
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBranch(int branchId) async {
    final repository = _repository;
    if (repository == null) return;
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        repository.categories(branchId),
        repository.products(branchId),
      ]);
      _categoriesByBranch[branchId] = results[0] as List<CatalogCategory>;
      _productsByBranch[branchId] = results[1] as List<CatalogProduct>;
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<CatalogCategory> categoriesForBranch(int branchId) =>
      List<CatalogCategory>.unmodifiable(
        _categoriesByBranch[branchId] ?? const <CatalogCategory>[],
      );

  List<CatalogProduct> productsForBranch(int branchId) =>
      List<CatalogProduct>.unmodifiable(
        _productsByBranch[branchId] ?? const <CatalogProduct>[],
      );

  Future<List<CatalogProduct>> search(int branchId, String query) async {
    final repository = _repository;
    if (repository == null || query.trim().isEmpty) {
      return productsForBranch(branchId);
    }
    return repository.products(branchId, search: query);
  }

  Future<CatalogProduct?> loadProduct(int branchId, int productId) async {
    final repository = _repository;
    if (repository == null) return null;
    return repository.product(branchId, productId);
  }

  Future<CatalogProductAvailability?> loadAvailability(
    int branchId,
    int productId,
  ) async {
    final repository = _repository;
    if (repository == null || !repository.context.usesApi) return null;
    return repository.availability(branchId, productId);
  }

  Future<CatalogPricingQuote?> quoteProduct({
    required int branchId,
    required String orderType,
    required int productId,
    required int quantity,
    int? variantId,
    List<int> optionValueIds = const <int>[],
  }) async {
    final repository = _repository;
    if (repository == null || !repository.context.usesApi) return null;
    return repository.quoteProduct(
      branchId: branchId,
      orderType: orderType,
      productId: productId,
      quantity: quantity,
      variantId: variantId,
      optionValueIds: optionValueIds,
    );
  }
}
