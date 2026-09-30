import '../data/customer_repository.dart';
import 'customer_catalog_models.dart';
import '../../features/location/models/branch.dart';

class CustomerCatalogRepository {
  final CustomerRepositoryContext context;

  const CustomerCatalogRepository(this.context);

  Future<List<Branch>> branches({String? service}) async {
    if (!context.usesApi) return const <Branch>[];
    final payload = await context.apiClient.getJson(
      '/api/v1/customer/branches',
      query: <String, Object?>{
        if (service != null) 'service': service,
        'accepting_orders': 1,
        'per_page': 100,
      },
    );
    final data = _dataMap(payload);
    return _items(data).map(branchFromApi).toList(growable: false);
  }

  Future<List<CatalogCategory>> categories(int branchId) async {
    if (!context.usesApi) return const <CatalogCategory>[];
    final payload = await context.apiClient.getJson(
      '/api/v1/customer/branches/$branchId/menu',
    );
    final data = _dataMap(payload);
    final raw = data['categories'] as List? ?? const <dynamic>[];
    return _flattenCategories(raw);
  }

  Future<List<CatalogProduct>> products(
    int branchId, {
    int? categoryId,
    String? search,
  }) async {
    if (!context.usesApi) return const <CatalogProduct>[];
    final payload = await context.apiClient.getJson(
      '/api/v1/customer/branches/$branchId/products',
      query: <String, Object?>{
        if (categoryId != null) 'category_id': categoryId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'per_page': 100,
      },
    );
    final data = _dataMap(payload);
    return _items(data)
        .map(CatalogProduct.fromJson)
        .toList(growable: false);
  }

  Future<CatalogProduct> product(int branchId, int productId) async {
    final payload = await context.apiClient.getJson(
      '/api/v1/customer/branches/$branchId/products/$productId',
    );
    return CatalogProduct.fromJson(_dataMap(payload));
  }

  Future<Map<String, dynamic>> availability(int branchId, int productId) async {
    final payload = await context.apiClient.getJson(
      '/api/v1/customer/branches/$branchId/products/$productId/availability',
    );
    return _dataMap(payload);
  }

  Future<List<int>> favoriteProductIds() async {
    final payload = await context.apiClient.getJson(
      '/api/v1/customer/favorites',
      authenticated: true,
      query: const <String, Object?>{'per_page': 100},
    );
    final data = _dataMap(payload);
    return _items(data)
        .map((item) => item['product'] is Map
            ? (Map<String, dynamic>.from(item['product'] as Map)['id'] as num?)
                ?.toInt()
            : (item['product_id'] as num?)?.toInt())
        .whereType<int>()
        .toList(growable: false);
  }

  Future<void> addFavorite(int productId) async {
    await context.apiClient.postJson(
      '/api/v1/customer/favorites/$productId',
      authenticated: true,
    );
  }

  Future<void> removeFavorite(int productId) async {
    await context.apiClient.requestJson(
      'DELETE',
      '/api/v1/customer/favorites/$productId',
      authenticated: true,
    );
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    return data is Map ? Map<String, dynamic>.from(data) : payload;
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> data) {
    final raw = data['items'] as List? ?? const <dynamic>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  List<CatalogCategory> _flattenCategories(List<dynamic> rows) {
    final result = <CatalogCategory>[];
    for (final raw in rows.whereType<Map>()) {
      final row = Map<String, dynamic>.from(raw);
      result.add(CatalogCategory.fromJson(row));
      final children = row['children'];
      if (children is List) result.addAll(_flattenCategories(children));
    }
    return result;
  }
}
