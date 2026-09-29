import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/products/product_type.dart';

void main() {
  group('GetinProductCatalog', () {
    test('maps menu categories to product types', () {
      expect(
        GetinProductCatalog.typeFromCategory('Coffee'),
        ProductType.drink,
      );
      expect(
        GetinProductCatalog.typeFromCategory('Food'),
        ProductType.food,
      );
      expect(
        GetinProductCatalog.typeFromCategory('Bakery'),
        ProductType.bakery,
      );
      expect(
        GetinProductCatalog.typeFromCategory('Refreshments'),
        ProductType.refreshment,
      );
      expect(
        GetinProductCatalog.typeFromCategory('Merchandise'),
        ProductType.merchandise,
      );
    });

    test('infers known product types from names', () {
      expect(
        GetinProductCatalog.definitionFor('Iced Latte').type,
        ProductType.drink,
      );
      expect(
        GetinProductCatalog.definitionFor('Turkey & Cheese').type,
        ProductType.food,
      );
      expect(
        GetinProductCatalog.definitionFor('Blueberry Muffin').type,
        ProductType.bakery,
      );
      expect(
        GetinProductCatalog.definitionFor('Berry Hibiscus').type,
        ProductType.refreshment,
      );
      expect(
        GetinProductCatalog.definitionFor('Getin Travel Tumbler').type,
        ProductType.merchandise,
      );
    });

    test('best seller badge is not applied to every product', () {
      expect(
        GetinProductCatalog.definitionFor('Iced Latte').badge,
        'BEST SELLER',
      );
      expect(
        GetinProductCatalog.definitionFor('Caramel Macchiato').badge,
        isNull,
      );
      expect(
        GetinProductCatalog.definitionFor('Turkey & Cheese').badge,
        isNull,
      );
    });

    test('explicit menu type overrides name inference', () {
      expect(
        GetinProductCatalog.definitionFor(
          'House Special',
          explicitType: ProductType.merchandise,
        ).type,
        ProductType.merchandise,
      );
    });

    test('beverage helper includes drinks and refreshments only', () {
      expect(ProductType.drink.isBeverage, isTrue);
      expect(ProductType.refreshment.isBeverage, isTrue);
      expect(ProductType.food.isBeverage, isFalse);
      expect(ProductType.bakery.isBeverage, isFalse);
      expect(ProductType.merchandise.isBeverage, isFalse);
    });
  });
}
