import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('Phase 5 secondary banner widget consumes remote content', () {
    final source = File('lib/features/home/widgets/secondary_banner_card.dart').readAsStringSync();
    expect(source, contains('secondaryBanners'));
    expect(source, contains('NetworkImage'));
  });
}
