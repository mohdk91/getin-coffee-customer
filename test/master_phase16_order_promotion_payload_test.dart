import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/orders/checkout_order_draft.dart';
import 'package:getin_coffee/core/orders/laravel_checkout_order_service.dart';

void main() {
  test('Task 173 sends the selected server promotion as coupon_code only', () {
    final draft = CheckoutOrderDraft(
      clientRequestId: 'phase16',
      createdAt: DateTime(2026, 10, 1),
      branchId: 1,
      branchName: 'GETIN',
      serviceType: 'pickup',
      currency: 'EGP',
      lines: const <CheckoutOrderLine>[
        CheckoutOrderLine(
          productId: 10,
          variantId: 20,
          optionValueIds: <int>[30],
          name: 'Coffee',
          productType: 'drink',
          description: '',
          image: '',
          basePrice: 100,
          unitPrice: 110,
          quantity: 1,
          size: null,
          temperature: null,
          milk: null,
          strength: '',
          sweetness: '',
          addOns: <String>[],
          variant: null,
          warming: null,
          sauce: null,
          color: null,
        ),
      ],
      itemCount: 1,
      specialRequest: '',
      deliveryAddress: null,
      deliveryInstruction: null,
      fulfilmentEstimate: '10 min',
      subtotal: 110,
      deliveryFee: 0,
      serviceFee: 0,
      tip: 0,
      membershipSaving: 0,
      rewardSaving: 99,
      rewardRedemptionId: '5',
      voucherSaving: 99,
      voucherCode: ' LIVE-REWARD-1 ',
      giftCardApplied: 0,
      paymentTender: 'card',
      paymentMethodId: null,
      paymentTokenReference: null,
      total: 1,
    );

    final payload = LaravelCheckoutOrderService.buildServerPayload(
      draft,
      includePayment: true,
    );

    expect(payload['coupon_code'], 'LIVE-REWARD-1');
    expect(payload, isNot(contains('reward_redemption_id')));
    expect(payload, isNot(contains('reward_saving')));
    expect(payload, isNot(contains('voucher_saving')));
    expect(payload, isNot(contains('gift_card_applied')));
    expect(payload, isNot(contains('total')));
  });
}
