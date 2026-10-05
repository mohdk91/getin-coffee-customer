import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-11G wires CocoaPods configs into Flutter iOS xcconfigs', () {
    final debug = File('ios/Flutter/Debug.xcconfig').readAsStringSync();
    final release = File('ios/Flutter/Release.xcconfig').readAsStringSync();
    final profile = File('ios/Flutter/Profile.xcconfig').readAsStringSync();
    final project =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

    expect(
      debug,
      contains(
        '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"',
      ),
    );
    expect(debug, contains('#include "Generated.xcconfig"'));

    expect(
      release,
      contains(
        '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"',
      ),
    );
    expect(release, contains('#include "Generated.xcconfig"'));

    expect(
      profile,
      contains(
        '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"',
      ),
    );
    expect(profile, contains('#include "Generated.xcconfig"'));

    expect(project, contains('Profile.xcconfig'));
  });
}
