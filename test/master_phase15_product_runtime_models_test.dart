import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/catalog/customer_catalog_models.dart';

void main() {
  test('Task 160 parses rich product configuration and availability', () {
    final product = CatalogProduct.fromJson(<String, dynamic>{
      'id': 41,
      'name': 'Configured Latte',
      'short_description': 'Live product',
      'description': 'Long description',
      'ingredients': 'Coffee, milk',
      'allergens': 'Milk',
      'product_type': 'variable',
      'is_featured': true,
      'catalog_price': '70.00',
      'currency': 'EGP',
      'preparation_time_minutes': 8,
      'calories': 220,
      'category': <String, dynamic>{'id': 2, 'name': 'Coffee'},
      'gallery': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 9,
          'url': 'https://cdn.test/product.webp',
          'alt_text': 'Configured latte',
          'is_primary': true,
        },
      ],
      'variants': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 11,
          'name': 'Large Oat',
          'price_adjustment': 10,
          'is_default': true,
          'is_available': true,
          'option_values': <Map<String, dynamic>>[
            <String, dynamic>{'id': 101, 'option_group_id': 7},
          ],
        },
      ],
      'option_groups': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 7,
          'code': 'size',
          'name': 'Size',
          'description': 'Choose one size',
          'selection_type': 'single',
          'is_required': true,
          'min_select': 1,
          'max_select': 1,
          'values': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 101,
              'code': 'large',
              'name': 'Large',
              'price_adjustment': 0,
              'is_default': true,
            },
          ],
        },
      ],
    });

    final availability = CatalogProductAvailability.fromJson(<String, dynamic>{
      'branch_id': 3,
      'product_id': 41,
      'available': true,
      'status': 'available',
      'stock_tracked': true,
      'variants': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 11,
          'available': true,
          'status': 'available',
          'stock_tracked': true,
        },
      ],
    });

    expect(product.isVariable, isTrue);
    expect(product.ingredients, 'Coffee, milk');
    expect(product.galleryItems.single.isPrimary, isTrue);
    expect(product.variants.single.optionValues.single.optionGroupId, 7);
    expect(product.optionGroups.single.code, 'size');
    expect(product.optionGroups.single.effectiveMinimum, 1);
    expect(availability.variantAvailable(11), isTrue);
  });

  test('Task 160 parses authoritative single-item pricing quote', () {
    final quote = CatalogPricingQuote.fromJson(<String, dynamic>{
      'branch_id': 3,
      'currency': 'EGP',
      'order_type': 'pickup',
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'product_id': 41,
          'variant_id': 11,
          'unit_total': '95.00',
          'line_total': '190.00',
        },
      ],
      'tax_total': '10.00',
      'total': '200.00',
    });

    expect(quote.unitTotal, 95);
    expect(quote.lineTotal, 190);
    expect(quote.displayUnitTotal, 'EGP 95');
  });
}
