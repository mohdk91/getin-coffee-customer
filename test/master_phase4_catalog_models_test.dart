import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/catalog/customer_catalog_models.dart';

void main() {
  test('Phase 4 parses server price, gallery, variants and options', () {
    final product = CatalogProduct.fromJson(<String, dynamic>{
      'id': 10,
      'name': 'Latte',
      'short_description': 'Coffee',
      'product_type': 'drink',
      'is_featured': true,
      'catalog_price': 65,
      'currency': 'EGP',
      'category': <String, dynamic>{'id': 2, 'name': 'Coffee'},
      'gallery': <Map<String, dynamic>>[{'url': 'https://cdn.test/1.webp'}],
      'variants': <Map<String, dynamic>>[{
        'id': 4, 'name': 'Large', 'price_adjustment': 10,
        'is_default': false, 'is_available': true,
      }],
      'option_groups': <Map<String, dynamic>>[{
        'id': 7, 'name': 'Milk', 'is_required': true, 'min_select': 1, 'max_select': 1,
        'values': <Map<String, dynamic>>[{
          'id': 8, 'name': 'Oat', 'price_adjustment': 15, 'is_default': false,
        }],
      }],
    });
    expect(product.displayPrice, 'EGP 65');
    expect(product.gallery, hasLength(1));
    expect(product.variants.single.isAvailable, isTrue);
    expect(product.optionGroups.single.values.single.priceAdjustment, 15);
  });
}
