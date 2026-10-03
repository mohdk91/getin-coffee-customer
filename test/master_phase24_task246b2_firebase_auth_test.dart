import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/auth/customer_account_repository.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/data/customer_repository.dart';
import 'package:getin_coffee/core/network/api_client.dart';
import 'package:getin_coffee/core/network/api_transport.dart';
import 'package:getin_coffee/core/storage/secure_store.dart';

class _Transport implements ApiTransport {
  Uri? uri;
  Object? body;

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    Map<String, String> headers = const {},
    Object? body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    this.uri = uri;
    this.body = body;
    return ApiRawResponse(
      statusCode: 200,
      body: jsonEncode(<String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'customer': <String, dynamic>{
            'id': 21,
            'name': 'Firebase Customer',
            'email': 'firebase@example.com',
            'phone': '+201000000000',
            'language': 'en',
            'status': 'active',
            'email_verified': true,
            'phone_verified': true,
          },
          'token': 'sanctum-firebase-token',
          'token_type': 'Bearer',
        },
      }),
      headers: const <String, String>{},
    );
  }
}

void main() {
  test('Task 246B-2 includes FlutterFire client configuration', () {
    expect(File('lib/firebase_options.dart').existsSync(), isTrue);
    expect(File('android/app/google-services.json').existsSync(), isTrue);
    expect(File('ios/Runner/GoogleService-Info.plist').existsSync(), isTrue);

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('firebase_core: 3.8.1'));
    expect(pubspec, contains('firebase_auth: 5.3.4'));
  });

  test('Task 246B-2 keeps runApp ahead of Firebase bootstrap work', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main.indexOf('runApp('), lessThan(main.indexOf('CustomerAppBootstrap.instance.start')));

    final bootstrap =
        File('lib/core/bootstrap/customer_app_bootstrap.dart').readAsStringSync();
    expect(bootstrap, contains('CustomerFirebaseAuthService.initialize'));
    expect(bootstrap, contains('CustomerMobileAppSettingsStore.initialize'));
  });

  test('mobile login is OTP-first when server enables Firebase phone auth', () {
    final screen = File('lib/features/auth/phone_login_screen.dart').readAsStringSync();
    expect(screen, contains("_settings.defaultMethod == 'password'"));
    expect(screen, contains("'Get Code'"));
    expect(screen, contains("'Use password instead'"));
    expect(screen, contains('startPhoneVerification'));
  });

  test('Firebase phone OTP preserves minimum 30-second resend cooldown', () {
    final screen = File('lib/features/auth/firebase_phone_otp_screen.dart')
        .readAsStringSync();
    expect(screen, contains('configured < 30 ? 30 : configured'));
    expect(screen, contains("'Resend Code in 00:"));
  });

  test('Firebase ID token is exchanged for GETIN Sanctum auth', () async {
    final transport = _Transport();
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://portal.getincoffee.com',
    );
    final context = CustomerRepositoryContext(
      config: config,
      secureStore: MemorySecureStore(),
      apiClient: ApiClient(config, transport: transport),
    );

    final result = await CustomerAccountRepository(context).firebaseLogin(
      idToken: 'firebase-id-token',
      displayName: 'Firebase Customer',
    );

    expect(transport.uri?.path, '/api/v1/customer/auth/firebase');
    expect(result.token, 'sanctum-firebase-token');
    expect(result.customer.id, 21);
  });
}
