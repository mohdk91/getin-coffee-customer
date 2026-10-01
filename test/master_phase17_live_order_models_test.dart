import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/orders/live_order_models.dart';

void main() {
  test('Task 177 parses authoritative Laravel order detail', () {
    final detail = LiveOrderDetail.fromJson(<String, dynamic>{
      'id': 41,
      'order_number': 'GC-41',
      'order_type': 'delivery',
      'status': 'completed',
      'payment_status': 'paid',
      'payment_method': 'card',
      'subtotal': '100.00',
      'discount_total': '10.00',
      'delivery_fee': '5.00',
      'tax_total': '2.00',
      'total': '97.00',
      'currency': 'EGP',
      'branch': <String, dynamic>{'id': 3, 'name': 'Smouha'},
      'delivery_address': <String, dynamic>{
        'address_line_1': 'Street 1',
        'city': 'Alexandria',
        'latitude': 31.2,
        'longitude': 29.9,
      },
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 8,
          'product_id': 12,
          'variant_id': 15,
          'product_name': 'Latte',
          'quantity': 2,
          'unit_price': '40.00',
          'options_total': '5.00',
          'line_total': '90.00',
          'options': <String, dynamic>{'milk': 'Oat'},
        },
      ],
      'timeline': <Map<String, dynamic>>[
        <String, dynamic>{'status': 'placed', 'at': '2026-10-01T10:00:00Z'},
      ],
    });

    expect(detail.id, 41);
    expect(detail.branchId, 3);
    expect(detail.items.single.productId, 12);
    expect(detail.items.single.variantId, 15);
    expect(detail.items.single.quantity, 2);
    expect(detail.deliveryAddress?.formatted, contains('Alexandria'));
    expect(detail.mayOfferRefund, isTrue);
  });

  test('Task 177 parses delivery PIN and QR without inventing credentials', () {
    final pin = LiveDeliveryPin.fromJson(<String, dynamic>{
      'order_id': 41,
      'pin': '012345',
      'expires_at': '2026-10-01T10:10:00Z',
      'attempts_remaining': 5,
    });
    final qr = LiveDeliveryQr.fromJson(<String, dynamic>{
      'order_id': 41,
      'token': 'server-token',
      'qr_payload': 'getin://delivery/verify?order=41&token=server-token',
      'expires_at': '2026-10-01T10:03:00Z',
    });

    expect(pin.pin, '012345');
    expect(pin.attemptsRemaining, 5);
    expect(qr.payload, contains('server-token'));
  });
}
