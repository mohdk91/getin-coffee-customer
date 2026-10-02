import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/bootstrap/customer_app_bootstrap.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/network/api_client.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'http://127.0.0.1:8000',
  );

  testWidgets('bootstrap paints a branded first frame before work completes',
      (tester) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerAppBootstrapGate(
          config: config,
          bootstrapper: (_) => completer.future,
          child: const Text('READY'),
        ),
      ),
    );

    expect(find.text('Preparing GETIN…'), findsOneWidget);
    expect(find.text('READY'), findsNothing);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.text('READY'), findsOneWidget);
  });

  test('legacy /v1 routes normalize to Laravel /api/v1 routes', () {
    const client = ApiClient(config);

    expect(
      client.endpoint('/v1/system/config').path,
      '/api/v1/system/config',
    );
    expect(
      client.endpoint('/v1/customer/login').path,
      '/api/v1/customer/login',
    );
    expect(
      client.endpoint('/api/v1/customer/branches').path,
      '/api/v1/customer/branches',
    );
  });

  test('main no longer performs store bootstrap before runApp', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('runApp(GetinCoffeeApp(config: config));'));
    expect(source, isNot(contains('CustomerAuthStore.initialize')));
    expect(source, isNot(contains('CustomerCatalogStore.initialize')));
  });

  test('Android native launch window uses GETIN brand background', () {
    for (final path in <String>[
      'android/app/src/main/res/drawable/launch_background.xml',
      'android/app/src/main/res/drawable-v21/launch_background.xml',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('@color/ic_launcher_background'));
      expect(source, isNot(contains('?android:colorBackground')));
    }
  });
}
