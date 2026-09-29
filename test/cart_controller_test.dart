import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/features/cart/cart_controller.dart';

void main() {
  final cart = CartController.instance;

  CartItem item({
    String branch = 'Getin Stanley',
    String service = 'delivery',
    String milk = 'Full Fat',
    int quantity = 1,
  }) {
    return CartItem(
      name: 'Iced Latte',
      description: 'Test drink',
      image: 'assets/images/products/iced_latte.png',
      branchName: branch,
      serviceType: service,
      currency: 'EGP',
      basePrice: 65,
      unitPrice: 75,
      quantity: quantity,
      size: 'Large',
      temperature: 'Iced',
      milk: milk,
      strength: 'Regular',
      sweetness: 'Regular',
      addOns: const [],
    );
  }

  setUp(() {
    cart.clear();
  });

  test('identical configurations merge quantities', () {
    cart.addOrMerge(item());
    cart.addOrMerge(item(quantity: 2));

    expect(cart.items.length, 1);
    expect(cart.itemCount, 3);
    expect(cart.subtotal, 225);
  });

  test('different configurations stay separate', () {
    cart.addOrMerge(item());
    cart.addOrMerge(item(milk: 'Oat Milk'));

    expect(cart.items.length, 2);
    expect(cart.itemCount, 2);
  });

  test('different branch is rejected by cart policy', () {
    cart.addOrMerge(item());

    expect(
      cart.canAccept(
        item(branch: 'Getin Smouha'),
      ),
      isFalse,
    );
  });

  test('different fulfilment type is rejected', () {
    cart.addOrMerge(item());

    expect(
      cart.canAccept(
        item(service: 'pickup'),
      ),
      isFalse,
    );
  });
}
