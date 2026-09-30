import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/auth/customer_session_repository.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/data/customer_repository.dart';
import 'package:getin_coffee/core/network/api_client.dart';
import 'package:getin_coffee/core/network/api_transport.dart';
import 'package:getin_coffee/core/storage/secure_store.dart';

class _LogoutTransport implements ApiTransport {
  final List<String> calls = <String>[];

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    calls.add('$method ${uri.path}');
    return ApiRawResponse(
      statusCode: 200,
      body: jsonEncode(<String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'revoked_count': 2},
      }),
    );
  }
}

void main() {
  test('Task 24 maps current and all-session logout endpoints', () async {
    final transport = _LogoutTransport();
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://api.example.com/api',
    );
    final secure = MemorySecureStore();
    await secure.write(SecureStoreKeys.accessToken, 'token');
    final repository = CustomerSessionRepository(
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

    await repository.revokeCurrent();
    await repository.revokeAll();

    expect(
      transport.calls,
      contains('DELETE /api/v1/customer/sessions/current'),
    );
    expect(transport.calls, contains('DELETE /api/v1/customer/sessions'));
  });
}
