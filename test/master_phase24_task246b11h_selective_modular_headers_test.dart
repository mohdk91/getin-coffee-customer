import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-11H scopes modular headers to Firebase iOS pods', () {
    final podfile = File('ios/Podfile').readAsStringSync();

    expect(
      RegExp(r'^\s*use_modular_headers!\s*$', multiLine: true)
          .hasMatch(podfile),
      isFalse,
      reason:
          'Global modular headers can break unrelated Swift Flutter plugins such as speech_to_text.',
    );

    const requiredPods = <String>[
      'FirebaseAuth',
      'FirebaseCore',
      'FirebaseCoreInternal',
      'FirebaseCoreExtension',
      'FirebaseAuthInterop',
      'FirebaseAppCheckInterop',
      'GoogleUtilities',
      'RecaptchaInterop',
    ];

    for (final pod in requiredPods) {
      expect(
        podfile,
        contains("pod '$pod', :modular_headers => true"),
        reason: '$pod must expose a module map for the Firebase static pod graph.',
      );
    }

    expect(podfile, contains("platform :ios, '15.5'"));
  });
}
