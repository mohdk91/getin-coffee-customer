import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:getin_coffee/core/settings/customer_settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await CustomerSettingsStore.instance.resetForTesting();
  });

  test('Task 16 defaults are usable', () {
    final store = CustomerSettingsStore.instance;
    expect(store.phone, '+20 10 0000 0000');
    expect(store.email, 'mohammed@example.com');
    expect(store.language, 'English');
    expect(store.appearance, 'System Default');
    expect(store.enabledNotificationCount,
        CustomerSettingsStore.notificationKeys.length);
  });

  test('contact and preference changes persist in the local store', () async {
    final store = CustomerSettingsStore.instance;
    await store.setPhone('+20 111 222 3333');
    await store.setEmail('demo@getin.coffee');
    await store.setLanguage('العربية');
    await store.setAppearance('Dark');
    await store.setBiometricLogin(true);
    await store.setNotification('New products', false);

    expect(store.phone, '+20 111 222 3333');
    expect(store.email, 'demo@getin.coffee');
    expect(store.language, 'العربية');
    expect(store.appearance, 'Dark');
    expect(store.biometricLogin, isTrue);
    expect(store.notifications['New products'], isFalse);
  });

  test('sessions, privacy and support demo actions are functional', () async {
    final store = CustomerSettingsStore.instance;
    await store.signOutOtherDemoSessions();
    await store.setAnalytics(false);
    await store.requestDataExport();
    final request = await store.addSupportRequest(
      topic: 'Order Issue',
      message: 'Demo order support request',
      contextId: 'GC-10582',
      contextLabel: 'Order GC-10582 · Delivery · Out for delivery',
      issueType: 'Missing item',
    );

    expect(store.otherDemoSessionActive, isFalse);
    expect(store.analytics, isFalse);
    expect(store.lastDataExportAt, isNotNull);
    expect(request.id, startsWith('GET-'));
    expect(request.contextId, 'GC-10582');
    expect(request.issueType, 'Missing item');
    expect(request.contextSummary, contains('Order GC-10582'));
    expect(store.supportRequests, hasLength(1));
  });
}
