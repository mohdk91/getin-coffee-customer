import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/orders/checkout_order_draft.dart';
import 'package:getin_coffee/core/orders/checkout_order_service.dart';

void main() {
  CheckoutOrderDraft draft({
    String serviceType = 'pickup',
    CheckoutDeliveryAddress? address,
  }) {
    return CheckoutOrderDraft(
      clientRequestId: 'test-request',
      createdAt: DateTime(2026, 9, 24),
      branchName: 'Getin Stanley',
      serviceType: serviceType,
      currency: 'EGP',
      lines: const [
        CheckoutOrderLine(
          name: 'Iced Latte',
          productType: 'drink',
          description: 'Demo drink',
          image: 'assets/demo.png',
          basePrice: 65,
          unitPrice: 75,
          quantity: 2,
          size: 'Large',
          temperature: 'Iced',
          milk: 'Oat Milk',
          strength: 'Strong',
          sweetness: 'Less Sweet',
          addOns: ['Extra Shot'],
          variant: null,
          warming: null,
          sauce: null,
          color: null,
        ),
      ],
      itemCount: 2,
      specialRequest: 'No straw',
      deliveryAddress: address,
      deliveryInstruction: null,
      fulfilmentEstimate: '10–15 min',
      subtotal: 150,
      deliveryFee: 0,
      serviceFee: 7.5,
      tip: 0,
      membershipSaving: 0,
      rewardSaving: 0,
      rewardRedemptionId: null,
      voucherSaving: 20,
      voucherCode: 'GETIN20',
      giftCardApplied: 40,
      paymentTender: 'card',
      paymentMethodId: 'demo-card',
      paymentTokenReference: 'demo_pm_token',
      total: 97.5,
    );
  }

  test('API payload keeps exact item configuration and no raw card data', () {
    final payload = draft().toApiPayload();
    final item = (payload['items'] as List).first as Map<String, dynamic>;
    final configuration = item['configuration'] as Map<String, dynamic>;
    final payment = payload['payment'] as Map<String, dynamic>;

    expect(configuration['size'], 'Large');
    expect(configuration['milk'], 'Oat Milk');
    expect(configuration['add_ons'], ['Extra Shot']);
    expect(payment['payment_method_id'], 'demo-card');
    expect(payment['payment_token_reference'], 'demo_pm_token');
    expect(payment.containsKey('card_number'), isFalse);
    expect(payment.containsKey('cvv'), isFalse);
  });

  test('demo order service returns a result without mutating the draft',
      () async {
    final orderDraft = draft();
    final result =
        await DemoCheckoutOrderService.instance.createOrder(orderDraft);

    expect(result.success, isTrue);
    expect(result.orderId, startsWith('DEMO-'));
    expect(orderDraft.lines.single.quantity, 2);
  });

  test('demo service rejects delivery without an address', () async {
    final result = await DemoCheckoutOrderService.instance.createOrder(
      draft(serviceType: 'delivery'),
    );

    expect(result.success, isFalse);
    expect(result.orderId, isNull);
  });
}
