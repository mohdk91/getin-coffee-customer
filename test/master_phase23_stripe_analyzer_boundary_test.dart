import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 238D excludes only vendored Stripe internals from app analysis', () {
    final options = File('analysis_options.yaml').readAsStringSync();

    expect(options, contains('analyzer:'));
    expect(options, contains('exclude:'));
    expect(options, contains('third_party/stripe_platform_interface/**'));
    expect(options, isNot(contains('- third_party/**')));
    expect(options, isNot(contains('- lib/**')));
    expect(options, isNot(contains('- test/**')));
  });
}
