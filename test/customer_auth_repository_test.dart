import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/data/customer_repository.dart';
import 'package:getin_coffee/core/network/api_client.dart';
import 'package:getin_coffee/core/network/api_transport.dart';
import 'package:getin_coffee/core/storage/secure_store.dart';
import 'package:getin_coffee/core/auth/customer_account_repository.dart';

class _Transport implements ApiTransport {
  String? method;
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
    this.method = method;
    this.uri = uri;
    this.body = body;
    return ApiRawResponse(
      statusCode: 200,
      body: jsonEncode(<String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'customer': <String, dynamic>{
            'id': 7,
            'name': 'GETIN Customer',
            'email': 'customer@example.com',
            'phone': '+201000000000',
            'language': 'en',
            'status': 'active',
            'email_verified': true,
            'phone_verified': true,
          },
          'token': 'token-123',
          'token_type': 'Bearer',
        },
      }),
      headers: const <String, String>{},
    );
  }
}

void main() {

  test('Task 17 login uses the Laravel customer login endpoint', () async {
    final transport = _Transport();
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://api.example.com/api',
    );
    final store = MemorySecureStore();
    final client = ApiClient(config, transport: transport);
    final context = CustomerRepositoryContext(
      config: config,
      secureStore: store,
      apiClient: client,
    );
    final repository = CustomerAccountRepository(context);

    final result = await repository.login(
      identifier: 'customer@example.com',
      password: 'Password123',
    );

    expect(transport.method, 'POST');
    expect(transport.uri?.path, '/api/v1/customer/login');
    expect(result.customer.id, 7);
    expect(result.token, 'token-123');
  });


  test('Task 18 registration maps Laravel customer auth response', () async {
    final transport = _Transport();
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://api.example.com/api',
    );
    final context = CustomerRepositoryContext(
      config: config,
      secureStore: MemorySecureStore(),
      apiClient: ApiClient(config, transport: transport),
    );
    final repository = CustomerAccountRepository(context);

    final result = await repository.register(
      name: 'New Customer',
      email: 'new@example.com',
      phone: '+201000000001',
      password: 'Password123',
      passwordConfirmation: 'Password123',
      referralCode: 'friend10',
    );

    expect(transport.method, 'POST');
    expect(transport.uri?.path, '/api/v1/customer/register');
    expect(result.token, 'token-123');
  });
}
