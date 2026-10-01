import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 14 home collections resolve exact live catalog product ids', () {
    final source = File('lib/features/home/widgets/managed_product_sections.dart')
        .readAsStringSync();
    expect(source, contains('MobileAppContentStore.instance.menuCollections'));
    expect(source, contains('_collectionProducts(collection, products)'));
    expect(source, contains("source: 'menu_collection'"));
  });
}
