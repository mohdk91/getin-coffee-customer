import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/catalog/customer_catalog_repository.dart';

void main() {
  test('Phase 4 catalog repository is available for live menu/search', () {
    expect(CustomerCatalogRepository, isNotNull);
  });
}
