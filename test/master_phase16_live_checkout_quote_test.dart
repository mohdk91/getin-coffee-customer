import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/orders/live_checkout_quote_service.dart';

void main() {
  test('Task 171 live quote payload carries identities and one promotion code', () {
    final payload = LiveCheckoutQuoteService.buildPayload(
      orderType: 'pickup',
      items: const <LiveCheckoutQuoteItem>[
        LiveCheckoutQuoteItem(
          productId: 10,
          variantId: 20,
          optionValueIds: <int>[30, 31],
          quantity: 2,
        ),
      ],
      promotionCode: ' LIVE-20 ',
    );

    expect(payload['coupon_code'], 'LIVE-20');
    expect(payload, isNot(contains('subtotal')));
    expect(payload, isNot(contains('total')));
    final item = (payload['items'] as List).single as Map<String, dynamic>;
    expect(item['product_id'], 10);
    expect(item, isNot(contains('unit_price')));
  });

  test('Task 171 parses authoritative pricing and promotion metadata', () {
    final quote = LiveCheckoutQuote.fromResponse(<String, dynamic>{
      'data': <String, dynamic>{
        'checkout_ready': true,
        'reasons': <dynamic>[],
        'pricing': <String, dynamic>{
          'currency': 'EGP',
          'subtotal': '120.00',
          'discount_total': '20.00',
          'delivery_fee': '0.00',
          'tax_total': '14.00',
          'total': '114.00',
          'promotion': <String, dynamic>{
            'kind': 'voucher',
            'code': 'LIVE20',
            'name': 'Live voucher',
            'discount_amount': '20.00',
          },
        },
      },
    });

    expect(quote.checkoutReady, isTrue);
    expect(quote.total, 114);
    expect(quote.promotionCode, 'LIVE20');
    expect(quote.promotionDiscount, 20);
  });
}
