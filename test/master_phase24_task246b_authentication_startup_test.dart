import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/network/api_client.dart';
import 'package:getin_coffee/features/auth/otp_screen.dart';
import 'package:getin_coffee/features/auth/sign_in_screen.dart';

void main() {
  test('Task 246B startup keeps the real video splash asset', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/videos/getin_splash_compat.mp4'));
    final splash = File('lib/features/splash/splash_screen.dart').readAsStringSync();
    expect(splash, contains("VideoPlayerController.asset('assets/videos/getin_splash_compat.mp4')"));
    final main = File('lib/main.dart').readAsStringSync();
    expect(main.indexOf('runApp('), lessThan(main.indexOf('CustomerAppBootstrap.instance.start')));
  });

  testWidgets('sign in exposes Google Apple and mobile actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Mobile Number'), findsOneWidget);
  });

  testWidgets('OTP resend is locked for 30 seconds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OtpScreen(phoneNumber: '+201000000000'),
      ),
    );
    expect(find.text('Resend Code in 00:30'), findsOneWidget);
    final button = tester.widget<TextButton>(find.byType(TextButton).last);
    expect(button.onPressed, isNull);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Resend Code'), findsOneWidget);
  });

  test('API path normalization supports root and /api base URLs', () {
    const rootConfig = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://127.0.0.1:8000',
    );
    const apiConfig = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://api.example.com/api',
    );

    expect(
      const ApiClient(rootConfig).endpoint('/v1/customer/login').path,
      '/api/v1/customer/login',
    );
    expect(
      const ApiClient(apiConfig).endpoint('/v1/customer/login').path,
      '/api/v1/customer/login',
    );
    expect(
      const ApiClient(apiConfig).endpoint('/api/v1/customer/login').path,
      '/api/v1/customer/login',
    );
  });

  test('social auth dart-define config is optional but explicit', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://127.0.0.1:8000',
      googleServerClientId: 'google-web-client.apps.googleusercontent.com',
    );
    expect(config.googleSignInConfigured, isTrue);
  });
}
