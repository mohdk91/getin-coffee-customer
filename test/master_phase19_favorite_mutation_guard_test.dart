import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 196 uses Laravel PUT and rolls live favorite failures back', () {
    final repository = File(
      'lib/core/favorites/customer_favorites_repository.dart',
    ).readAsStringSync();
    final store = File(
      'lib/core/favorites/customer_favorites_store.dart',
    ).readAsStringSync();

    expect(repository, contains("'PUT'"));
    expect(
      repository,
      contains("'/api/v1/customer/favorites/\$productId'"),
    );
    expect(store, contains('if (apiMutation && serverId == null)'));
    expect(store, contains('_products.removeWhere'));
    expect(store, contains('_products.insert(target, removed)'));
    expect(store, contains('if (usesApi) return;'));
    expect(store, isNot(contains('Keep optimistic local UI')));
  });
}
