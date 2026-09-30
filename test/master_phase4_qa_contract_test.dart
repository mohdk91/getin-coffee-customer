import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/catalog/customer_catalog_store.dart';
import 'package:getin_coffee/features/location/services/branch_service.dart';

void main() {
  test('Master Phase 4 live catalog wiring is present', () {
    expect(CustomerCatalogStore.instance, isNotNull);
    expect(BranchService.branches, isNotEmpty);
  });
}
