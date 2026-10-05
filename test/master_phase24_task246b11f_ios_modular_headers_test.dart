import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Task 246B-11F Firebase module-map requirement remains satisfied by selective scope',
    () {
      final podfile = File('ios/Podfile').readAsStringSync();

      // Task 246B-11H intentionally replaced the old global
      // `use_modular_headers!` workaround because it interfered with unrelated
      // mixed Swift/Objective-C Flutter plugins such as speech_to_text.
      expect(
        RegExp(r'^\s*use_modular_headers!\s*$', multiLine: true)
            .hasMatch(podfile),
        isFalse,
        reason:
            'Modular headers must remain scoped to Firebase/Google pods rather than enabled globally.',
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
          reason:
              '$pod must still expose a module map for the Firebase static CocoaPods graph.',
        );
      }

      expect(podfile, contains("platform :ios, '15.5'"));
    },
  );
}
