import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/content/mobile_app_content_models.dart';

void main() {
  test('Phase 14 parses published market context and menu collections', () {
    final snapshot = MobileAppContentSnapshot.fromJson(<String, dynamic>{
      'market_context': <String, dynamic>{
        'id': 7,
        'code': 'EG-ALEXANDRIA',
        'name': 'Alexandria · EG',
        'currency': 'EGP',
      },
      'menu_collections': <dynamic>[
        <String, dynamic>{
          'id': 11,
          'slug': 'featured',
          'title': 'Featured',
          'is_featured': true,
          'sort_order': 2,
          'product_ids': <dynamic>[10, 20],
        },
      ],
    });

    expect(snapshot.marketContext?.code, 'EG-ALEXANDRIA');
    expect(snapshot.marketContext?.currency, 'EGP');
    expect(snapshot.menuCollections.single.productIds, <int>[10, 20]);
  });
}
