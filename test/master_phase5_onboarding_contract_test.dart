import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('Phase 5 onboarding consumes mobile content store', () {
    final source = File('lib/features/onboarding/onboarding_screen.dart').readAsStringSync();
    expect(source, contains('MobileAppContentStore.instance.onboarding'));
    expect(source, contains('Image.network'));
  });
}
