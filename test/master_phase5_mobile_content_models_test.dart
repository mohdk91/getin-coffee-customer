import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/content/mobile_app_content_models.dart';

void main() {
  test('Phase 5 parses splash, banners and home sections', () {
    final snapshot = MobileAppContentSnapshot.fromJson(<String, dynamic>{
      'splash': <String, dynamic>{
        'id': 1,
        'type': 'splash',
        'internal_name': 'Launch',
        'sort_order': 0,
        'media': <String, dynamic>{'type': 'video', 'url': 'https://x.test/s.mp4'},
        'destination': <String, dynamic>{'type': 'none'},
      },
      'hero_banners': <dynamic>[],
      'secondary_banners': <dynamic>[],
      'home_sections': <dynamic>[
        <String, dynamic>{'id': 2, 'key': 'best_sellers', 'title': 'Best Sellers', 'source': 'featured_products', 'sort_order': 30},
      ],
    });
    expect(snapshot.splash?.media?.type, 'video');
    expect(snapshot.homeSections.single.key, 'best_sellers');
  });
}
