import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 195 uses numeric product identity for live favorites', () {
    final store = File(
      'lib/core/favorites/customer_favorites_store.dart',
    ).readAsStringSync();
    final menu = File('lib/features/menu/menu_screen.dart').readAsStringSync();
    final liveDetail = File(
      'lib/features/product/live_product_detail_screen.dart',
    ).readAsStringSync();

    expect(store, contains("'server:\$serverProductId'"));
    expect(store, contains('containsServerProductId'));
    expect(menu, contains('serverProductId: product.id'));
    expect(liveDetail, contains('serverProductId: product.id'));
    expect(liveDetail, contains('Icons.favorite_border_rounded'));
  });
}
