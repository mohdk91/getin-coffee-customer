import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-7 replaces hardcoded Profile stats with live preview stores', () {
    final source = File(
      'lib/features/profile/profile_screen.dart',
    ).readAsStringSync();

    expect(source, contains('CustomerMembershipStore.instance'));
    expect(source, contains('CustomerStampCardStore.instance'));
    expect(source, contains('vouchers.availableCount'));
    expect(source, contains('stamps.currentStamps'));
    expect(source, contains('stamps.requiredStamps'));
    expect(source, contains('membership.earningMultiplierLabel'));
    expect(source, isNot(contains("('2', 'Vouchers'")));
    expect(source, isNot(contains("'EGP 280'")));
  });

  test('Task 246B-7 gives signed-out Personal Information complete content', () {
    final source = File(
      'lib/features/profile/profile_pages.dart',
    ).readAsStringSync();

    expect(source, contains("firstName.text = 'GETIN';"));
    expect(source, contains("lastName.text = 'Customer';"));
    expect(source, contains('CustomerSettingsStore.instance'));
    expect(source, contains('DateTime(1995, 4, 18)'));
    expect(source, contains('CustomerCountryStore.current.value'));
  });

  test('Task 246B-7 makes About, legal and support pages customer ready', () {
    final settings = File(
      'lib/features/profile/settings_detail_screens.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/profile/profile_pages.dart',
    ).readAsStringSync();

    expect(settings, contains('SettingsAboutArticleType.locations'));
    expect(settings, contains('SettingsAboutArticleType.careers'));
    expect(settings, contains('SettingsAboutArticleType.contact'));
    expect(settings, contains("title: 'Locations'"));
    expect(settings, contains("title: 'Careers'"));
    expect(settings, contains("title: 'Contact Us'"));
    expect(settings, contains('Stars and stamps are earned on eligible completed orders.'));
    expect(profile, contains('SettingsLegalScreen(type: legalType)'));
    expect(profile, contains('SettingsAboutArticleScreen(type: articleType)'));
  });

  test('Task 246B-7 removes customer-facing implementation placeholder copy', () {
    final settings = File(
      'lib/features/profile/settings_detail_screens.dart',
    ).readAsStringSync();
    final settingsHome = File(
      'lib/features/profile/settings_screen.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/profile/profile_pages.dart',
    ).readAsStringSync();

    for (final forbidden in <String>[
      'connected to Laravel',
      'CMS/backend',
      'Local Demo',
      'local demo request',
      'Delete Demo Account',
      'Verify Demo',
      'This action is destructive in production',
      'Data export request will connect to backend',
    ]) {
      expect(settings, isNot(contains(forbidden)), reason: forbidden);
      expect(settingsHome, isNot(contains(forbidden)), reason: forbidden);
      expect(profile, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
