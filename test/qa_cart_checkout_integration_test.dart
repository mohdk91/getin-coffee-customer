import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/features/cart/cart_controller.dart';
import 'package:getin_coffee/features/orders/orders_screen.dart';

void main() {
  final cart = CartController.instance;

  CartItem item({
    String branch = 'Getin Stanley',
    String service = 'delivery',
    int quantity = 1,
  }) {
    return CartItem(
      name: 'Iced Latte',
      description: 'QA drink',
      image: 'assets/images/products/iced_latte.png',
      branchName: branch,
      serviceType: service,
      currency: 'EGP',
      basePrice: 65,
      unitPrice: 75,
      quantity: quantity,
      size: 'Large',
      temperature: 'Iced',
      milk: 'Full Fat',
      strength: 'Regular',
      sweetness: 'Regular',
      addOns: const [],
    );
  }

  setUp(() {
    cart.clear();
    CustomerOrdersController.instance.clearCreatedOrdersForTesting();
  });

  test('cart controller blocks mixed branch additions at the state boundary',
      () {
    expect(cart.addOrMerge(item()), isTrue);
    expect(
      cart.addOrMerge(item(branch: 'Getin Smouha')),
      isFalse,
    );
    expect(cart.items, hasLength(1));
    expect(cart.cartBranchName, 'Getin Stanley');
  });

  test(
      'cart controller blocks mixed fulfilment additions at the state boundary',
      () {
    expect(cart.addOrMerge(item()), isTrue);
    expect(
      cart.addOrMerge(item(service: 'pickup')),
      isFalse,
    );
    expect(cart.items, hasLength(1));
    expect(cart.cartServiceType, 'delivery');
  });

  test('removing the final item clears order-scoped special request', () {
    final added = item();
    cart.addOrMerge(added);
    cart.setSpecialRequest('Leave at reception');

    cart.remove(added.signature);

    expect(cart.isEmpty, isTrue);
    expect(cart.specialRequest, isEmpty);
  });

  test('newly created order is available to the Orders session controller', () {
    final order = GetinOrder(
      id: 'DEMO-123456',
      placedAt: DateTime(2026, 9, 24),
      branchName: 'Getin Stanley',
      fulfillment: 'Delivery',
      status: GetinOrderStatus.confirmed,
      itemCount: 1,
      total: 'EGP 102.49',
      itemImages: const ['assets/images/products/iced_latte.png'],
    );

    CustomerOrdersController.instance.addCreatedOrder(order);

    expect(CustomerOrdersController.instance.createdOrders, hasLength(1));
    expect(CustomerOrdersController.instance.createdOrders.single.id,
        'DEMO-123456');
  });
}
