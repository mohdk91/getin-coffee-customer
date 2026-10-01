import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 162 API product detail delegates to live runtime loader', () {
    final legacy = File('lib/features/product/product_detail_screen.dart')
        .readAsStringSync();
    final live = File('lib/features/product/live_product_detail_screen.dart')
        .readAsStringSync();

    expect(legacy, contains('CustomerCatalogStore.instance.usesApi'));
    expect(legacy, contains('LiveProductDetailScreen('));
    expect(live, contains('CustomerCatalogStore.instance.loadProduct'));
    expect(live, contains('CustomerCatalogStore.instance.loadAvailability'));
    expect(live, contains('No demo configuration will be substituted'));
  });
}
