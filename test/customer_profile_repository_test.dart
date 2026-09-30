import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/auth/customer_account_repository.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/data/customer_repository.dart';
import 'package:getin_coffee/core/network/api_client.dart';
import 'package:getin_coffee/core/network/api_transport.dart';
import 'package:getin_coffee/core/storage/secure_store.dart';

class _ProfileTransport implements ApiTransport {
  String? method;
  Uri? uri;
  Object? body;

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    this.method = method;
    this.uri = uri;
    this.body = body;
    return ApiRawResponse(
      statusCode: 200,
      body: jsonEncode(<String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'id': 7,
          'name': method == 'PATCH' ? 'Updated Customer' : 'GETIN Customer',
          'email': 'customer@example.com',
          'phone': '+201000000000',
          'language': 'en',
          'status': 'active',
          'email_verified': true,
          'phone_verified': true,
          'gender': 'male',
          'date_of_birth': '1988-02-04',
          'country_code': 'EG',
        },
      }),
    );
  }
}

void main() {
  test('Task 20 reads and updates authenticated customer profile', () async {
    final transport = _ProfileTransport();
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://api.example.com/api',
    );
    final secureStore = MemorySecureStore();
    await secureStore.write(SecureStoreKeys.accessToken, 'token');
    final client = ApiClient(
      config,
      transport: transport,
      tokenProvider: () => secureStore.read(SecureStoreKeys.accessToken),
    );
    final repository = CustomerAccountRepository(
      CustomerRepositoryContext(
        config: config,
        secureStore: secureStore,
        apiClient: client,
      ),
    );

    final profile = await repository.fetchProfile();
    expect(transport.uri?.path, '/api/v1/customer/profile');
    expect(profile.gender, 'male');
    expect(profile.countryCode, 'EG');

    final updated = await repository.updateProfile(<String, dynamic>{
      'name': 'Updated Customer',
      'gender': 'male',
      'date_of_birth': '1988-02-04',
      'country_code': 'EG',
    });
    expect(transport.method, 'PATCH');
    expect(updated.name, 'Updated Customer');
  });
}
