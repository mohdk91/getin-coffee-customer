import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 201 isolates live favorites and reviews from demo state', () {
    final reviews =
        File('lib/features/reviews/review_screens.dart').readAsStringSync();
    final profile =
        File('lib/features/profile/profile_pages.dart').readAsStringSync();

    expect(
      reviews,
      contains('GETIN does not expose this review type in the production API.'),
    );
    expect(
      reviews,
      contains('Nothing was saved locally.'),
    );
    expect(profile, contains('Refresh from GETIN'));
    expect(profile, contains("product.image.startsWith('http')"));
    expect(profile, contains('AppNavigationController.instance.openMenu()'));
    expect(
      profile,
      contains("labels: CustomerFavoritesStore.instance.usesApi"),
    );
    expect(
      profile,
      contains('else if (!CustomerFavoritesStore.instance.usesApi)'),
    );
  });
}
