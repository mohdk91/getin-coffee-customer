import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-11D aligns iOS scanner and Firebase CocoaPods graph', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final podfile = File('ios/Podfile').readAsStringSync();
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final codemagic = File('codemagic.yaml').readAsStringSync();
    final stripeContract =
        File('test/master_phase23_stripe_runtime_test.dart').readAsStringSync();

    expect(pubspec, contains('mobile_scanner: 6.0.11'));
    expect(pubspec, isNot(contains('enable-swift-package-manager:')));
    expect(podfile, contains("platform :ios, '15.5'"));
    expect(project, contains('IPHONEOS_DEPLOYMENT_TARGET = 15.5;'));
    expect(stripeContract, contains('IPHONEOS_DEPLOYMENT_TARGET = 15.5;'));
    expect(stripeContract, isNot(contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0;')));
    expect(codemagic, contains('flutter config --no-enable-swift-package-manager'));
    expect(codemagic, contains('rm -f Podfile.lock'));
    expect(codemagic, contains('pod install --repo-update'));
    expect(codemagic, contains('distribution_type: app_store'));
    expect(codemagic, contains('bundle_identifier: com.getincoffee.getinCoffee'));
  });
}
