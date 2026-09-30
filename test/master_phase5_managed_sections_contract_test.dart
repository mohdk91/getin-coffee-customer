import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('Phase 5 managed home product sections use live catalog', () {
    final source = File('lib/features/home/widgets/managed_product_sections.dart').readAsStringSync();
    expect(source, contains('CustomerCatalogStore.instance.productsForBranch'));
    expect(source, isNot(contains('assets/images/home/sections')));
  });
}
