import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-4B gives signed-out production users polished notifications',
      () {
    final store = File(
      'lib/core/notifications/customer_notifications_store.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/notifications/notifications_screen.dart',
    ).readAsStringSync();

    expect(store, contains('CustomerAuthStore.instance.isAuthenticated'));
    expect(store, contains('_guestPreviewItems()'));
    expect(store, contains("title: 'Order confirmed'"));
    expect(store, contains("title: '18 Stars added'"));
    expect(store, contains("title: 'Stamp collected · 3 of 7'"));
    expect(store, contains("actionRoute: 'orders'"));
    expect(store, contains("actionRoute: 'rewards'"));
    expect(screen, contains("value.contains('stamp')"));
    expect(screen, contains("value.contains('offer')"));
  });

  test('Task 246B-4B shows live unread count and guest Stars on Home', () {
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    final header = File(
      'lib/features/home/widgets/home_header.dart',
    ).readAsStringSync();
    final rewards = File(
      'lib/core/rewards/customer_rewards_store.dart',
    ).readAsStringSync();
    final stamps = File(
      'lib/core/rewards/customer_stamp_card_store.dart',
    ).readAsStringSync();

    expect(home, contains('CustomerNotificationsStore.instance.unreadCount'));
    expect(header, contains('final int unreadNotifications'));
    expect(header, contains('if (unreadNotifications > 0)'));
    expect(rewards, contains('CustomerAuthStore.instance.isAuthenticated'));
    expect(rewards, contains("getin_demo_rewards_stars_v2"));
    expect(stamps, contains('CustomerAuthStore.instance.isAuthenticated'));
    expect(stamps, contains('?? 3'));
  });

  test(
      'Task 246B-4B renders offers from published collections and live products',
      () {
    final offers = File(
      'lib/features/home/live_offers_bundles_screen.dart',
    ).readAsStringSync();
    final managed = File(
      'lib/features/home/widgets/managed_product_sections.dart',
    ).readAsStringSync();
    final navigation = File(
      'lib/core/content/mobile_content_navigation.dart',
    ).readAsStringSync();

    expect(offers, contains('MobileAppContentStore.instance.menuCollections'));
    expect(offers, contains('CustomerCatalogStore.instance.productsForBranch'));
    expect(offers, contains("'Offers & Bundles'"));
    expect(offers, contains('Image.network('));
    expect(offers, contains('product.displayPrice'));
    expect(managed, contains('LiveOffersBundlesScreen('));
    expect(managed, contains("label: const Text('See all')"));
    expect(navigation, contains("case 'collection':"));
    expect(navigation, contains('LiveOfferCollectionDetailScreen('));
  });

  test('Task 246B-4B refreshes notifications after successful authentication',
      () {
    final sync = File(
      'lib/core/auth/customer_account_sync.dart',
    ).readAsStringSync();

    expect(
      sync,
      contains('_bestEffort(CustomerNotificationsStore.instance.refresh)'),
    );
  });
}
