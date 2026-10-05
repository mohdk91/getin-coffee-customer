import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-11J keeps speech recognition compatible with iOS archive and Android', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lockLines = File('pubspec.lock').readAsLinesSync();
    final podfile = File('ios/Podfile').readAsStringSync();

    expect(pubspec, contains('speech_to_text: 7.1.0'));

    final start = lockLines.indexOf('  speech_to_text:');
    expect(start, greaterThanOrEqualTo(0));

    var end = lockLines.length;
    for (var i = start + 1; i < lockLines.length; i++) {
      final line = lockLines[i];
      if (line.startsWith('  ') &&
          !line.startsWith('    ') &&
          line.endsWith(':')) {
        end = i;
        break;
      }
    }

    final block = lockLines.sublist(start, end).join('\n');
    expect(block, contains('version: "7.1.0"'));

    expect(
      RegExp(r'^\s*use_modular_headers!\s*$', multiLine: true)
          .hasMatch(podfile),
      isFalse,
    );
    expect(
      podfile,
      contains("pod 'FirebaseAuth', :modular_headers => true"),
    );
    expect(podfile, contains("platform :ios, '15.5'"));
  });
}
