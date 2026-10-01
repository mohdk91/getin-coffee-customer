import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 176 keeps live promotions server authoritative end to end', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final engagement = File(
      'lib/core/engagement/customer_engagement_api_repository.dart',
    ).readAsStringSync();
    final rewards = File(
      'lib/core/rewards/customer_rewards_store.dart',
    ).readAsStringSync();
    final cart = File(
      'lib/features/cart/cart_controller.dart',
    ).readAsStringSync();
    final liveQuote = File(
      'lib/core/orders/live_checkout_quote_service.dart',
    ).readAsStringSync();
    final checkout = File(
      'lib/features/checkout/checkout_screen.dart',
    ).readAsStringSync();
    final orderService = File(
      'lib/core/orders/laravel_checkout_order_service.dart',
    ).readAsStringSync();
    final giftCards = File(
      'lib/core/gift_cards/customer_gift_card_store.dart',
    ).readAsStringSync();

    expect(
      mainSource,
      contains('CustomerVoucherStore.initialize(CustomerAuthStore.instance.context)'),
    );
    expect(engagement, contains("'/v1/customer/vouchers'"));
    expect(engagement, contains("'/v1/customer/vouchers/\$voucherId/validate'"));
    expect(rewards, contains("voucher['voucher_code']"));
    expect(rewards, isNot(contains("'REWARD-\${item['id']}'")));

    expect(cart, contains('if (CustomerRewardsStore.instance.usesApi)'));
    expect(cart, contains('if (CustomerVoucherStore.instance.usesApi)'));
    expect(cart, contains('return 0;'));

    expect(liveQuote, contains("'coupon_code': promotionCode.trim()"));
    expect(liveQuote, isNot(contains("'unit_price':")));
    expect(liveQuote, isNot(contains("'subtotal':")));
    expect(liveQuote, isNot(contains("'total':")));

    expect(checkout, contains('Future<bool> _refreshLiveQuote'));
    expect(checkout, contains('_LiveCheckoutSummary('));
    expect(
      RegExp(r'class _LiveCheckoutSummary extends StatelessWidget')
          .allMatches(checkout)
          .length,
      1,
    );
    expect(checkout, isNot(contains('Remove local preview rewards, vouchers')));
    expect(checkout, contains('CustomerVoucherStore.instance.refresh()'));
    expect(checkout, contains('CustomerRewardsStore.instance.refresh()'));
    expect(
      checkout,
      contains('Gift Card Balance cannot be spent in live checkout'),
    );

    expect(orderService, contains("'coupon_code': draft.voucherCode!.trim()"));
    expect(orderService, isNot(contains("'reward_redemption_id':")));
    expect(orderService, isNot(contains("'gift_card_amount':")));

    expect(giftCards, contains('Future<double> spendBalance'));
    expect(giftCards, contains('if (usesApi)'));
  });
}
