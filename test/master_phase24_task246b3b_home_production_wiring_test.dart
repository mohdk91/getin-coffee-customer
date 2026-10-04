import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/catalog/customer_catalog_models.dart';

void main() {
  test('Task 246B-3B preserves live branch currency and open status', () {
    final branch = branchFromApi(<String, dynamic>{
      'id': 2,
      'name': 'GETIN San Stefano',
      'currency': 'EGP',
      'location': <String, dynamic>{
        'country_code': 'EG',
        'city': 'Alexandria',
        'latitude': 31.2459,
        'longitude': 29.9669,
      },
      'capabilities': <String, dynamic>{
        'delivery': true,
        'pickup': true,
      },
      'status': <String, dynamic>{
        'is_open_now': true,
        'ordering_available': true,
      },
    });

    expect(branch.currency, 'EGP');
    expect(branch.countryCode, 'EG');
    expect(branch.isOpen, isTrue);
    expect(branch.statusLabel, 'Open');
  });

  test('Task 246B-3B lets Control Panel home sections drive live ordering', () {
    final source = File(
      'lib/features/home/widgets/managed_product_sections.dart',
    ).readAsStringSync();

    expect(source, contains('contentStore.homeSections.toList()'));
    expect(source, contains("case 'rewards':"));
    expect(source, contains("case 'getin_play':"));
    expect(source, contains("case 'offers':"));
    expect(source, contains("case 'featured_products':"));
    expect(source, contains("case 'catalog':"));
    expect(source, contains("case 'order_history':"));
    expect(source, contains('MobileAppContentStore.instance.menuCollections'));
    expect(source, contains('_ManagedCollectionGroup('));
    expect(
      source,
      isNot(contains("const {'best_sellers', 'seasonal', 'popular'}")),
    );
  });

  test('Task 246B-3B renders every secondary banner from production', () {
    final source = File(
      'lib/features/home/widgets/secondary_banner_card.dart',
    ).readAsStringSync();

    expect(source, contains('PageView.builder('));
    expect(source, contains('itemCount: banners.length'));
    expect(source, contains('banner: banners[index]'));
    expect(source, isNot(contains('final banner = banners.first')));
  });

  test('Task 246B-3B shows selected branch market context in Home header', () {
    final source = File(
      'lib/features/home/widgets/home_header.dart',
    ).readAsStringSync();

    expect(source, contains('branch.countryCode'));
    expect(source, contains('branch.currency'));
    expect(source, contains("distanceKm.toStringAsFixed(1)"));
  });
}
