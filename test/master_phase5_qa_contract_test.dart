import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Master Phase 5 mobile content wiring is present', () {
    expect(File('lib/core/content/mobile_app_content_store.dart').existsSync(), isTrue);
    expect(File('lib/core/content/mobile_content_navigation.dart').existsSync(), isTrue);
    expect(File('lib/features/home/widgets/hero_carousel.dart').existsSync(), isTrue);
    expect(File('lib/features/home/widgets/secondary_banner_card.dart').existsSync(), isTrue);
    expect(File('lib/features/home/widgets/managed_product_sections.dart').existsSync(), isTrue);
  });
}
