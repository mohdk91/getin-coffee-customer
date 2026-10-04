import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:getin_coffee/features/home/home_greeting.dart';

void main() {
  test('Task 246B-10B uses the device hour for customer greeting', () {
    expect(homeGreetingForHour(0), 'Good morning');
    expect(homeGreetingForHour(11), 'Good morning');
    expect(homeGreetingForHour(12), 'Good afternoon');
    expect(homeGreetingForHour(16), 'Good afternoon');
    expect(homeGreetingForHour(17), 'Good evening');
    expect(homeGreetingForHour(23), 'Good evening');

    final header = File(
      'lib/features/home/widgets/home_header.dart',
    ).readAsStringSync();
    expect(header, contains('homeGreetingForHour(DateTime.now().hour)'));
    expect(header, isNot(contains("'Good morning',")));
  });

  test('Task 246B-10B adds View All navigation to live Home product sections',
      () {
    final managed = File(
      'lib/features/home/widgets/managed_product_sections.dart',
    ).readAsStringSync();
    final listing = File(
      'lib/features/home/live_home_product_listing_screen.dart',
    ).readAsStringSync();

    expect(managed, contains('LiveHomeProductListingScreen('));
    expect(managed, contains('onSeeAll: showSeeAll'));
    expect(managed, contains("label: const Text('View all')"));
    expect(listing, contains('final List<CatalogProduct> products;'));
    expect(listing, contains('catalogProduct: product'));
    expect(listing, contains('branchId: branchId'));
  });

  test('Task 246B-10B shows Stars on linked Home product cards', () {
    final managed = File(
      'lib/features/home/widgets/managed_product_sections.dart',
    ).readAsStringSync();
    final listing = File(
      'lib/features/home/live_home_product_listing_screen.dart',
    ).readAsStringSync();

    for (final source in <String>[managed, listing]) {
      expect(source, contains('RewardEarningPolicy.starsForPrice('));
      expect(source, contains("'+\$earnedStars Stars"));
      expect(source, contains('membership.earningMultiplier'));
      expect(source, contains('membership.earningMultiplierLabel'));
    }
  });
}
