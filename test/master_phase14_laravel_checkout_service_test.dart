import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/orders/checkout_order_draft.dart';
import 'package:getin_coffee/core/orders/laravel_checkout_order_service.dart';

void main() {
  CheckoutOrderDraft draft() => CheckoutOrderDraft(
        clientRequestId: 'phase14-idempotency-key',
        createdAt: DateTime(2026, 10, 1),
        branchId: 7,
        branchName: 'Getin Stanley',
        serviceType: 'pickup',
        currency: 'EGP',
        lines: const <CheckoutOrderLine>[
          CheckoutOrderLine(
            productId: 91,
            variantId: 8,
            optionValueIds: <int>[12, 13],
            name: 'Latte',
            productType: 'drink',
            description: 'Live product',
            image: '',
            basePrice: 100,
            unitPrice: 155,
            quantity: 2,
            size: 'Large',
            temperature: 'Iced',
            milk: 'Oat',
            strength: 'Regular',
            sweetness: 'Regular',
            addOns: <String>[],
            variant: null,
            warming: null,
            sauce: null,
            color: null,
          ),
        ],
        itemCount: 2,
        specialRequest: 'No straw',
        deliveryAddress: null,
        deliveryInstruction: null,
        fulfilmentEstimate: '10–15 min',
        subtotal: 310,
        deliveryFee: 0,
        serviceFee: 7.5,
        tip: 0,
        membershipSaving: 0,
        rewardSaving: 20,
        rewardRedemptionId: 'local-preview-reward',
        voucherSaving: 10,
        voucherCode: 'LOCALONLY',
        giftCardApplied: 50,
        paymentTender: 'card',
        paymentMethodId: 'local-card',
        paymentTokenReference: 'local-token',
        total: 237.5,
      );

  test('live payload contains identities but no client monetary authority', () {
    final payload = LaravelCheckoutOrderService.buildServerPayload(
      draft(),
      includePayment: true,
    );
    final item = (payload['items'] as List).single as Map<String, dynamic>;

    expect(payload['order_type'], 'pickup');
    expect(payload['payment_method'], 'card');
    expect(item['product_id'], 91);
    expect(item['variant_id'], 8);
    expect(item['option_value_ids'], <int>[12, 13]);
    expect(item['quantity'], 2);

    for (final forbidden in <String>[
      'currency',
      'subtotal',
      'delivery_fee',
      'service_fee',
      'tip',
      'total',
      'reward_saving',
      'voucher_saving',
      'gift_card_applied',
    ]) {
      expect(payload.containsKey(forbidden), isFalse, reason: forbidden);
    }
    expect(item.containsKey('unit_price'), isFalse);
    expect(item.containsKey('base_price'), isFalse);
    expect(item.containsKey('line_total'), isFalse);
  });
}
