import '../data/customer_repository.dart';

class CustomerFavoritesRepository {
  final CustomerRepositoryContext context;
  const CustomerFavoritesRepository(this.context);

  bool get usesApi => context.usesApi;

  Future<Set<int>> listProductIds() async {
    final payload = await context.apiClient.getJson(
      '/api/v1/customer/favorites',
      authenticated: true,
      query: const <String, Object?>{'per_page': 100},
    );
    final data = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'] as Map)
        : const <String, dynamic>{};
    final items = data['items'] as List? ?? const <dynamic>[];
    return items.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      if (item['product'] is Map) {
        return (Map<String, dynamic>.from(item['product'] as Map)['id'] as num?)
            ?.toInt();
      }
      return (item['product_id'] as num?)?.toInt();
    }).whereType<int>().toSet();
  }

  Future<void> add(int productId) async {
    await context.apiClient.postJson(
      '/api/v1/customer/favorites/$productId',
      authenticated: true,
    );
  }

  Future<void> remove(int productId) async {
    await context.apiClient.requestJson(
      'DELETE',
      '/api/v1/customer/favorites/$productId',
      authenticated: true,
    );
  }
}
