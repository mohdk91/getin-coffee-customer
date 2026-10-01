import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/favorites/customer_favorites_repository.dart';

void main() {
  test('Task 194 parses server favorite product identity', () {
    final product = CustomerFavoriteRemoteProduct.fromJson(
      const <String, dynamic>{
        'id': 41,
        'slug': 'iced-latte',
        'name': 'Iced Latte',
        'short_description': 'Classic and cold',
        'image_url': 'https://cdn.example.com/iced-latte.jpg',
        'is_available': true,
      },
    );

    expect(product.id, 41);
    expect(product.slug, 'iced-latte');
    expect(product.name, 'Iced Latte');
    expect(product.isAvailable, isTrue);
  });

  test('Task 194 keeps API favorites server-backed at startup', () {
    final store = File(
      'lib/core/favorites/customer_favorites_store.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/core/favorites/customer_favorites_repository.dart',
    ).readAsStringSync();

    expect(store, contains('if (usesApi) {\n      await refreshFromServer();'));
    expect(store, contains('repository.listProducts()'));
    expect(store, contains("id: 'server:\${product.id}'"));
    expect(repository, contains("'/api/v1/customer/favorites'"));
  });
}
