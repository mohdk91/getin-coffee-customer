import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 238 hardens Stripe 11.5.0 for the project Flutter toolchain', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final vendoredPubspec =
        File('third_party/stripe_platform_interface/pubspec.yaml').readAsStringSync();
    final color = File(
      'third_party/stripe_platform_interface/lib/src/models/color.dart',
    ).readAsStringSync();

    expect(pubspec, contains('flutter_stripe: ^11.5.0'));
    expect(pubspec, contains('stripe_platform_interface:'));
    expect(pubspec, contains('path: third_party/stripe_platform_interface'));
    expect(vendoredPubspec, contains('name: stripe_platform_interface'));
    expect(vendoredPubspec, contains('version: 11.5.0'));

    // This project toolchain exposes the older integer component getters.
    // Keep the project-local Stripe interface compatible without changing
    // PaymentSheet, card-brand filtering, or any payment authority rules.
    expect(color, contains('red.toRadixString(16)'));
    expect(color, contains('green.toRadixString(16)'));
    expect(color, contains('blue.toRadixString(16)'));
    expect(color, contains('alpha.toRadixString(16)'));
    expect(color, isNot(contains('(r * 255)')));
    expect(color, isNot(contains('(g * 255)')));
    expect(color, isNot(contains('(b * 255)')));
    expect(color, isNot(contains('(a * 255)')));
  });
}
