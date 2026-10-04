import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'Task 246B-10C keeps live history authoritative and falls back only when empty',
      () {
    final orders =
        File('lib/features/orders/orders_screen.dart').readAsStringSync();

    expect(orders, contains('controller.createdOrders.isNotEmpty'));
    expect(orders, contains('return controller.createdOrders;'));
    expect(
      orders,
      contains(
          'return _previewLoggedIn ? _previewOrders : const <GetinOrder>[];'),
    );
    expect(orders, contains('final hasPreviewFallback ='));
    expect(orders, contains('!hasPreviewFallback'));
  });

  test(
      'Task 246B-10C restores rich order states with delivery handover details',
      () {
    final orders =
        File('lib/features/orders/orders_screen.dart').readAsStringSync();
    final detail =
        File('lib/features/orders/order_detail_screen.dart').readAsStringSync();

    expect(orders, contains("id: 'GC-10582'"));
    expect(orders, contains("id: 'GC-10561'"));
    expect(orders, contains("id: 'GC-10566'"));
    expect(orders, contains("id: 'GC-10540'"));
    expect(orders, contains("id: 'GC-10511'"));
    expect(orders, contains('GetinOrderStatus.outForDelivery'));
    expect(orders, contains('GetinOrderStatus.preparing'));
    expect(orders, contains('GetinOrderStatus.ready'));
    expect(orders, contains('GetinOrderStatus.delivered'));
    expect(orders, contains('GetinOrderStatus.cancelled'));
    expect(orders, contains("deliveryCode: '4729'"));
    expect(orders,
        contains("deliveryQrAsset: 'assets/images/demo_delivery_qr.png'"));
    expect(detail, contains("'Show QR & PIN'"));
    expect(detail, contains("'Backup PIN'"));
    expect(detail, contains('DriverChatScreen('));
  });

  test(
      'Task 246B-10C preserves cancellation details and preview review actions',
      () {
    final orders =
        File('lib/features/orders/orders_screen.dart').readAsStringSync();
    final detail =
        File('lib/features/orders/order_detail_screen.dart').readAsStringSync();

    expect(orders, contains('final String? cancellationReason;'));
    expect(orders, contains("'cancellationReason': cancellationReason"));
    expect(
      orders,
      contains('Customer changed delivery plans before preparation started.'),
    );
    expect(orders, contains('onRate: order.apiOrderId == null &&'));
    expect(detail, contains('order.cancellationReason?.isNotEmpty == true'));
    expect(detail, contains('order.cancellationReason!'));
  });
}
