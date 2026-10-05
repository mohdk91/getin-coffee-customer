import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-11F enables modular headers for Firebase iOS pods', () {
    final podfile = File('ios/Podfile').readAsStringSync();

    expect(podfile, contains("platform :ios, '15.5'"));
    expect(
      RegExp(
        r'^\s*use_modular_headers!\s*$',
        multiLine: true,
      ).hasMatch(podfile),
      isTrue,
      reason:
          'FirebaseAuth/Core Swift pods require module maps while the project uses static CocoaPods integration.',
    );
  });
}
