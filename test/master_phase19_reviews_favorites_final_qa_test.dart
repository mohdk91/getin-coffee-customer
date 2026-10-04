import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 202 keeps Phase 19 live social state server authoritative', () {
    final favoritesRepository = File(
      'lib/core/favorites/customer_favorites_repository.dart',
    ).readAsStringSync();
    final favoritesStore = File(
      'lib/core/favorites/customer_favorites_store.dart',
    ).readAsStringSync();
    final reviewStore = File(
      'lib/core/reviews/customer_review_store.dart',
    ).readAsStringSync();
    final liveOrder = File(
      'lib/features/orders/live_order_detail_screen.dart',
    ).readAsStringSync();
    final orders =
        File('lib/features/orders/orders_screen.dart').readAsStringSync();
    final reviewScreens =
        File('lib/features/reviews/review_screens.dart').readAsStringSync();

    expect(favoritesRepository, contains("'PUT'"));
    expect(favoritesStore, contains('await refreshFromServer();'));
    expect(favoritesStore, contains('containsServerProductId'));
    expect(favoritesStore, contains('_products.insert(target, removed)'));

    expect(reviewStore, contains('CustomerOrderReviewStatus'));
    expect(reviewStore, contains('status?.delivery.eligible != true'));
    expect(reviewStore, contains('status?.employee.eligible != true'));
    expect(reviewStore, contains('refreshed?.delivery.submitted == true'));
    expect(reviewStore, contains('refreshed?.employee.submitted == true'));

    expect(liveOrder, contains('_reviewStatus!.delivery.eligible'));
    expect(liveOrder, contains('_reviewStatus!.employee.eligible'));
    expect(
        orders, contains('onRate: (!controller.usesApi || !authenticated) &&'));
    expect(
      reviewScreens,
      contains('GETIN does not expose this review type in the production API.'),
    );

    expect(
      favoritesStore,
      isNot(contains('Keep optimistic local UI')),
    );
    expect(
      liveOrder,
      isNot(contains('Rate each product')),
    );
    expect(
      liveOrder,
      isNot(contains('Rate branch')),
    );
  });
}
