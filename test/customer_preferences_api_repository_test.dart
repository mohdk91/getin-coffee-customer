import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/data/customer_repository.dart';
import 'package:getin_coffee/core/network/api_client.dart';
import 'package:getin_coffee/core/network/api_transport.dart';
import 'package:getin_coffee/core/settings/customer_preferences_repository.dart';
import 'package:getin_coffee/core/storage/secure_store.dart';

class _PreferencesTransport implements ApiTransport {
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
          'language': method == 'PATCH' ? 'ar' : 'en',
          'marketing_notifications_enabled': true,
          'push_notifications_enabled': true,
          'in_app_notifications_enabled': true,
        },
      }),
    );
  }
}

void main() {
  test('Task 22 reads and updates Laravel customer preferences', () async {
    final transport = _PreferencesTransport();
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://api.example.com/api',
    );
    final secure = MemorySecureStore();
    await secure.write(SecureStoreKeys.accessToken, 'token');
    final repository = CustomerPreferencesRepository(
      CustomerRepositoryContext(
        config: config,
        secureStore: secure,
        apiClient: ApiClient(
          config,
          transport: transport,
          tokenProvider: () => secure.read(SecureStoreKeys.accessToken),
        ),
      ),
    );

    final current = await repository.fetch();
    expect(current.language, 'en');
    expect(transport.uri?.path, '/api/v1/customer/preferences');

    final updated = await repository.update(<String, dynamic>{'language': 'ar'});
    expect(transport.method, 'PATCH');
    expect(updated.language, 'ar');
  });
}
