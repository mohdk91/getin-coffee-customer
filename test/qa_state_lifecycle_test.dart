import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/products/product_type.dart';
import 'package:getin_coffee/core/reviews/customer_review_store.dart';
import 'package:getin_coffee/features/cart/cart_controller.dart';
import 'package:getin_coffee/features/orders/orders_screen.dart';
import 'package:getin_coffee/features/reviews/review_screens.dart';

void main() {
  test('cart item round-trips all order configuration fields', () {
    const item = CartItem(
      name: 'Iced Latte',
      description: 'QA drink',
      image: 'assets/images/products/iced_latte.png',
      branchName: 'Getin Stanley',
      serviceType: 'delivery',
      currency: 'EGP',
      basePrice: 65,
      unitPrice: 82,
      quantity: 2,
      size: 'Large',
      temperature: 'Iced',
      milk: 'Oat',
      strength: 'Strong',
      sweetness: 'Less Sweet',
      addOns: ['Extra Shot'],
      productType: ProductType.drink,
      variant: 'Classic',
    );

    final restored = CartItem.fromJson(item.toJson());

    expect(restored.signature, item.signature);
    expect(restored.quantity, 2);
    expect(restored.unitPrice, 82);
    expect(restored.addOns, ['Extra Shot']);
  });

  test('created order round-trips reviewable products and delivery context',
      () {
    final order = GetinOrder(
      id: 'DEMO-PERSIST',
      placedAt: DateTime(2026, 9, 24, 12, 30),
      branchName: 'Getin Stanley',
      fulfillment: 'Delivery',
      status: GetinOrderStatus.confirmed,
      itemCount: 1,
      total: 'EGP 102.49',
      itemImages: const ['assets/images/products/iced_latte.png'],
      reviewProducts: const [
        ReviewableProduct(
          name: 'Iced Latte',
          description: 'Double espresso, milk and ice.',
          image: 'assets/images/products/iced_latte.png',
          price: 'EGP 65',
        ),
      ],
      eta: '20–30 min',
      deliveryAddress: 'Home · Stanley',
      deliveryLatitude: 31.2453,
      deliveryLongitude: 29.9668,
      deliveryCode: '4728',
    );

    final restored = GetinOrder.fromJson(order.toJson());

    expect(restored.id, 'DEMO-PERSIST');
    expect(restored.status, GetinOrderStatus.confirmed);
    expect(restored.reviewProducts.single.name, 'Iced Latte');
    expect(restored.deliveryCode, '4728');
  });

  test('submitted review models retain order linkage when serialized', () {
    final review = CustomerProductReview(
      id: 'review-1',
      productName: 'Iced Latte',
      reviewerName: 'Mohammed',
      rating: 5,
      comment: 'Excellent.',
      createdAt: DateTime(2026, 9, 24),
      orderId: 'GC-TEST',
    );
    final driver = CustomerDriverReview(
      id: 'driver-review-1',
      orderId: 'GC-TEST',
      driverName: 'Omar Adel',
      rating: 5,
      comment: 'On time.',
      createdAt: DateTime(2026, 9, 24),
    );

    final restoredReview = CustomerProductReview.fromJson(review.toJson());
    final restoredDriver = CustomerDriverReview.fromJson(driver.toJson());

    expect(restoredReview.orderId, 'GC-TEST');
    expect(restoredReview.rating, 5);
    expect(restoredDriver.orderId, 'GC-TEST');
    expect(restoredDriver.driverName, 'Omar Adel');
  });
}
