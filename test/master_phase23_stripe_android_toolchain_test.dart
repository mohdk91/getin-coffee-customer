import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 238 aligns the Android toolchain with Stripe native Kotlin metadata', () {
    final settings = File('android/settings.gradle').readAsStringSync();
    final properties = File('android/gradle.properties').readAsStringSync();
    final wrapper = File(
      'android/gradle/wrapper/gradle-wrapper.properties',
    ).readAsStringSync();

    expect(
      settings,
      contains(
        'id "org.jetbrains.kotlin.android" version "2.2.20" apply false',
      ),
    );
    expect(
      settings,
      contains('id "com.android.application" version "8.10.1" apply false'),
    );
    expect(
      wrapper,
      contains('gradle-8.11.1-all.zip'),
    );
    expect(
      properties,
      contains('android.enableR8.fullMode=false'),
    );
  });
}
