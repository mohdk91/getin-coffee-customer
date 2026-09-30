import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/auth/customer_session_repository.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/data/customer_repository.dart';
import 'package:getin_coffee/core/network/api_client.dart';
import 'package:getin_coffee/core/network/api_transport.dart';
import 'package:getin_coffee/core/storage/secure_store.dart';
import 'package:getin_coffee/core/system/app_runtime_info.dart';

class _Runtime implements AppRuntimeInfoProvider {
  const _Runtime();
  @override
  Future<AppRuntimeInfo> load() async => const AppRuntimeInfo(
        platform: 'android',
        version: '1.0.0',
        buildNumber: '1',
      );
}

class _SessionTransport implements ApiTransport {
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
    Object? data;
    if (uri.path.endsWith('/sessions') && method == 'GET') {
      data = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 9,
          'name': 'customer-mobile',
          'is_current': true,
          'last_active_at': '2026-09-30T08:00:00Z',
          'expires_at': null,
          'device': <String, dynamic>{
            'id': 4,
            'device_id': 'device-123456',
            'platform': 'android',
            'device_name': 'Test Android',
            'app_version': '1.0.0+1',
            'os_version': 'Android',
            'push_notifications_registered': false,
          },
        },
      ];
    } else {
      data = <String, dynamic>{'ok': true};
    }
    return ApiRawResponse(
      statusCode: 200,
      body: jsonEncode(<String, dynamic>{'success': true, 'data': data}),
    );
  }
}

void main() {
  test('Task 23 registers device and manages Laravel customer sessions', () async {
    final transport = _SessionTransport();
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

    await repository.registerCurrentDevice(runtimeInfoProvider: const _Runtime());
    final sessions = await repository.listSessions();
    expect(sessions.single.isCurrent, isTrue);
    expect(sessions.single.device?.deviceName, 'Test Android');
    await repository.revokeSession(8);

    expect(transport.calls, contains('PUT /api/v1/customer/device'));
    expect(transport.calls, contains('GET /api/v1/customer/sessions'));
    expect(transport.calls, contains('DELETE /api/v1/customer/sessions/8'));
  });
}
