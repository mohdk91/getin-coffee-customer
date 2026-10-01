import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 165 consumes published gallery and product information', () {
    final models = File('lib/core/catalog/customer_catalog_models.dart')
        .readAsStringSync();
    final screen = File('lib/features/product/live_product_detail_screen.dart')
        .readAsStringSync();

    expect(models, contains("ingredients: json['ingredients']"));
    expect(models, contains("allergens: json['allergens']"));
    expect(models, contains("json['preparation_time_minutes']"));
    expect(screen, contains('_LiveProductGallery(product: product)'));
    expect(screen, contains('_LiveProductInformation(product: product)'));
    expect(screen, contains("('Ingredients', product.ingredients!.trim())"));
    expect(screen, contains("('Allergens', product.allergens!.trim())"));
    expect(screen, isNot(contains('Gallery structure is ready')));
    expect(screen, isNot(contains('12 in stock at this demo branch')));
  });
}
