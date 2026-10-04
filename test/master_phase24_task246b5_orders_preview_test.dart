import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'Task 246B-5 builds signed-out order previews from the live branch catalog',
      () {
    final orders = File(
      'lib/features/orders/orders_screen.dart',
    ).readAsStringSync();

    expect(orders, contains('CustomerCatalogStore.instance.productsForBranch'));
    expect(
        orders,
        contains(
            'final authenticated = CustomerAuthStore.instance.isAuthenticated'));
    expect(orders, contains("id: 'GC-10582'"));
    expect(orders, contains('GetinOrderStatus.outForDelivery'));
    expect(orders, contains('GetinOrderStatus.preparing'));
    expect(orders, contains('GetinOrderStatus.delivered'));
    expect(orders, contains('GetinOrderStatus.cancelled'));
    expect(orders, contains('product.displayPrice'));
    expect(orders, contains('product.imageUrl'));
    expect(orders, contains('assets/images/demo_delivery_qr.png'));
    expect(
      orders,
      contains(
          'controller.usesApi && authenticated && order.apiOrderId != null'),
    );
  });

  test('Task 246B-5 supports remote order media and QR or PIN handover', () {
    final orders = File(
      'lib/features/orders/orders_screen.dart',
    ).readAsStringSync();
    final detail = File(
      'lib/features/orders/order_detail_screen.dart',
    ).readAsStringSync();
    final media = File(
      'lib/features/orders/widgets/order_product_image.dart',
    ).readAsStringSync();

    expect(orders, contains('OrderProductImage('));
    expect(detail, contains('OrderProductImage('));
    expect(media, contains('Image.network('));
    expect(detail, contains("'Show QR & PIN'"));
    expect(detail, contains("'Backup PIN'"));
    expect(detail, contains("'Delivery verified'"));
    expect(File('assets/images/demo_delivery_qr.png').existsSync(), isTrue);
  });

  test('Task 246B-5 removes technical implementation copy from order screens',
      () {
    final detail = File(
      'lib/features/orders/order_detail_screen.dart',
    ).readAsStringSync();
    final live = File(
      'lib/features/orders/live_order_detail_screen.dart',
    ).readAsStringSync();

    expect(detail, isNot(contains('Demo order tracking is local-only')));
    expect(detail, isNot(contains('Production delivery tracking')));
    expect(live, isNot(contains('Server QR payload')));
    expect(live, isNot(contains('on the server')));
    expect(live, isNot(contains('Production currently supports')));
  });

  test(
      'Task 246B-5 makes Order Again visible from live catalog for guest preview',
      () {
    final managed = File(
      'lib/features/home/widgets/managed_product_sections.dart',
    ).readAsStringSync();

    expect(managed, contains("case 'order_history':"));
    expect(managed, contains('CustomerAuthStore.instance.isAuthenticated'));
    expect(managed, contains('_orderAgainPreviewProducts(products)'));
  });
}
