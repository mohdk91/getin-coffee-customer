import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/content/mobile_app_content_models.dart';

void main() {
  test('Phase 5 destination contract preserves type and value', () {
    final destination = MobileContentDestination.fromJson(
      <String, dynamic>{'type': 'product', 'value': '42'},
    );
    expect(destination.type, 'product');
    expect(destination.value, '42');
  });
}
