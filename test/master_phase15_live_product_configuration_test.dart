import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/catalog/customer_catalog_models.dart';
import 'package:getin_coffee/features/product/live_product_configuration.dart';

void main() {
  CatalogProduct product() => CatalogProduct.fromJson(<String, dynamic>{
        'id': 1,
        'name': 'Latte',
        'short_description': 'Coffee',
        'product_type': 'variable',
        'is_featured': false,
        'catalog_price': 70,
        'currency': 'EGP',
        'variants': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 10,
            'name': 'Small',
            'price_adjustment': 0,
            'is_default': true,
            'is_available': true,
            'option_values': <Map<String, dynamic>>[
              <String, dynamic>{'id': 100, 'option_group_id': 5},
            ],
          },
          <String, dynamic>{
            'id': 11,
            'name': 'Large',
            'price_adjustment': 10,
            'is_default': false,
            'is_available': true,
            'option_values': <Map<String, dynamic>>[
              <String, dynamic>{'id': 101, 'option_group_id': 5},
            ],
          },
        ],
        'option_groups': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 5,
            'name': 'Size',
            'selection_type': 'single',
            'is_required': true,
            'min_select': 1,
            'max_select': 1,
            'values': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 100,
                'name': 'Small',
                'price_adjustment': 0,
                'is_default': true,
              },
              <String, dynamic>{
                'id': 101,
                'name': 'Large',
                'price_adjustment': 0,
                'is_default': false,
              },
            ],
          },
          <String, dynamic>{
            'id': 6,
            'name': 'Milk',
            'selection_type': 'single',
            'is_required': true,
            'min_select': 1,
            'max_select': 1,
            'values': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 200,
                'name': 'Full Fat',
                'price_adjustment': 0,
                'is_default': true,
              },
              <String, dynamic>{
                'id': 201,
                'name': 'Oat',
                'price_adjustment': 15,
                'is_default': false,
              },
            ],
          },
        ],
      });

  const availability = CatalogProductAvailability(
    branchId: 9,
    productId: 1,
    available: true,
    status: 'available',
    stockTracked: true,
    variants: <CatalogVariantAvailability>[
      CatalogVariantAvailability(
        id: 10,
        available: true,
        status: 'available',
        stockTracked: true,
      ),
      CatalogVariantAvailability(
        id: 11,
        available: true,
        status: 'available',
        stockTracked: true,
      ),
    ],
  );

  test('Task 161 resolves mapped variants from server option choices', () {
    final config = LiveProductConfiguration(
      product: product(),
      availability: availability,
    );

    expect(config.complete, isTrue);
    expect(config.variantId, 10);
    expect(config.optionValueIds, containsAll(<int>[100, 200]));

    final size = config.product.optionGroups.first;
    config.toggleValue(size, size.values.last);

    expect(config.variantId, 11);
    expect(config.optionValueIds, containsAll(<int>[101, 200]));
  });

  test('Task 161 honors branch variant availability', () {
    final config = LiveProductConfiguration(
      product: product(),
      availability: const CatalogProductAvailability(
        branchId: 9,
        productId: 1,
        available: true,
        status: 'available',
        stockTracked: true,
        variants: <CatalogVariantAvailability>[
          CatalogVariantAvailability(
            id: 10,
            available: true,
            status: 'available',
            stockTracked: true,
          ),
          CatalogVariantAvailability(
            id: 11,
            available: false,
            status: 'out_of_stock',
            stockTracked: true,
          ),
        ],
      ),
    );

    final size = config.product.optionGroups.first;
    expect(config.isValueEnabled(size, size.values.last), isFalse);
  });
}
