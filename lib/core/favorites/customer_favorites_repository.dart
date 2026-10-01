import '../data/customer_repository.dart';

class CustomerFavoriteRemoteProduct {
  final int id;
  final String slug;
  final String name;
  final String description;
  final String imageUrl;
  final bool isAvailable;

  const CustomerFavoriteRemoteProduct({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isAvailable,
  });

  factory CustomerFavoriteRemoteProduct.fromJson(Map<String, dynamic> json) {
    return CustomerFavoriteRemoteProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['short_description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      isAvailable: json['is_available'] as bool? ?? false,
    );
  }
}

class CustomerFavoritesRepository {
  final CustomerRepositoryContext context;
  const CustomerFavoritesRepository(this.context);

  bool get usesApi => context.usesApi;

  Future<List<CustomerFavoriteRemoteProduct>> listProducts() async {
    final payload = await context.apiClient.getJson(
      '/api/v1/customer/favorites',
      authenticated: true,
      query: const <String, Object?>{'per_page': 100},
    );
    final data = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'] as Map)
        : const <String, dynamic>{};
    final items = data['items'] as List? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .map((item) => item['product'])
        .whereType<Map>()
        .map((raw) => CustomerFavoriteRemoteProduct.fromJson(
              Map<String, dynamic>.from(raw),
            ))
        .where((product) => product.id > 0 && product.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<Set<int>> listProductIds() async {
    final products = await listProducts();
    return products.map((product) => product.id).toSet();
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
