import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-8B removes implementation wording from customer-facing copy',
      () {
    const files = <String>[
      'lib/core/orders/live_order_lifecycle_service.dart',
      'lib/core/orders/laravel_checkout_order_service.dart',
      'lib/core/orders/live_driver_tracking_controller.dart',
      'lib/core/network/api_client.dart',
      'lib/core/auth/customer_account_repository.dart',
      'lib/core/auth/customer_session_repository.dart',
      'lib/core/products/product_type.dart',
      'lib/core/widgets/mobile_startup_gate.dart',
      'lib/core/vouchers/customer_voucher_store.dart',
      'lib/core/engagement/customer_engagement_api_repository.dart',
      'lib/core/data/customer_repository.dart',
      'lib/core/settings/customer_preferences_repository.dart',
      'lib/core/addresses/customer_address_repository.dart',
      'lib/core/favorites/customer_favorites_store.dart',
      'lib/features/profile/profile_pages.dart',
      'lib/features/checkout/checkout_screen.dart',
      'lib/features/product/product_detail_screen.dart',
      'lib/features/play/getin_play_screen.dart',
      'lib/features/splash/splash_screen.dart',
      'lib/features/chat/customer_support_chat_screen.dart',
      'lib/features/chat/driver_chat_screen.dart',
      'lib/features/cart/cart_controller.dart',
      'lib/features/vouchers/voucher_picker_sheet.dart',
      'lib/features/home/home_offer_detail_screen.dart',
      'lib/features/qr/qr_scanner_screen.dart',
      'lib/features/addresses/saved_addresses_screen.dart',
      'lib/features/gift_cards/gift_cards_screen.dart',
      'lib/features/reviews/review_screens.dart',
      'lib/features/payments/payment_methods_screen.dart',
    ];

    final forbidden = <String>[
      'local demo',
      'in this demo',
      'demo rules',
      'production api',
      'laravel could',
      'laravel will',
      'laravel calculates',
      'laravel api later',
      'laravel backend',
      'server-authoritative',
      'server voucher',
      'server identity',
      'server-backed saved address',
      'api connection',
      'laravel/cms',
      'authoritative checkout total',
      'getin api returned',
      'demo customer service',
      'synced with getin',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync().toLowerCase();
      for (final phrase in forbidden) {
        expect(
          source,
          isNot(contains(phrase)),
          reason:
              '$path still contains customer-facing implementation wording: $phrase',
        );
      }
    }
  });

  test('Task 246B-8B keeps customer-ready payment and support guidance', () {
    final checkout =
        File('lib/features/checkout/checkout_screen.dart').readAsStringSync();
    final support = File('lib/features/chat/customer_support_chat_screen.dart')
        .readAsStringSync();
    final vouchers = File('lib/features/vouchers/voucher_picker_sheet.dart')
        .readAsStringSync();
    final product = File('lib/features/product/product_detail_screen.dart')
        .readAsStringSync();

    expect(checkout, contains('Confirming latest pricing…'));
    expect(
        checkout,
        contains(
            'GETIN never receives or stores your full card number or CVC.'));
    expect(
        support, contains('GETIN support agent can join this conversation.'));
    expect(vouchers, contains('Final saving is confirmed at checkout.'));
    expect(product, contains('Availability can vary by branch.'));
  });
}
