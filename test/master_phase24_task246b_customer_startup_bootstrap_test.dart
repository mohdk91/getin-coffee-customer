import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/network/api_client.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'http://127.0.0.1:8000',
  );

  test('runApp is invoked before Customer bootstrap starts', () {
    final source = File('lib/main.dart').readAsStringSync();
    final runAppIndex =
        source.indexOf('runApp(GetinCoffeeApp(config: config));');
    final bootstrapIndex =
        source.indexOf('CustomerAppBootstrap.instance.start(config)');

    expect(runAppIndex, greaterThanOrEqualTo(0));
    expect(bootstrapIndex, greaterThan(runAppIndex));
  });

  test('video splash waits for Customer bootstrap before navigation', () {
    final source = File('lib/features/splash/splash_screen.dart').readAsStringSync();

    expect(
      source,
      contains(
        "VideoPlayerController.asset('assets/videos/getin_splash_compat.mp4')",
      ),
    );
    expect(source, contains('CustomerAppBootstrap.instance.ready'));
    expect(source, contains('CustomerAppBootstrap.instance.retry()'));
  });

  test('legacy /v1 routes normalize without duplicating /api', () {
    const client = ApiClient(config);
    const apiBaseConfig = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://api.example.com/api',
    );
    const apiBaseClient = ApiClient(apiBaseConfig);

    expect(client.endpoint('/v1/system/config').path, '/api/v1/system/config');
    expect(client.endpoint('/v1/customer/login').path, '/api/v1/customer/login');
    expect(
      client.endpoint('/api/v1/customer/branches').path,
      '/api/v1/customer/branches',
    );
    expect(
      apiBaseClient.endpoint('/v1/customer/login').path,
      '/api/v1/customer/login',
    );
    expect(
      apiBaseClient.endpoint('/api/v1/customer/login').path,
      '/api/v1/customer/login',
    );
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
