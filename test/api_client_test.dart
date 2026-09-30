import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/network/api_client.dart';
import 'package:getin_coffee/core/network/api_exception.dart';
import 'package:getin_coffee/core/network/api_transport.dart';

class _FakeTransport implements ApiTransport {
  final ApiRawResponse response;
  Uri? lastUri;
  Map<String, String>? lastHeaders;

  _FakeTransport(this.response);

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    lastUri = uri;
    lastHeaders = headers;
    return response;
  }
}

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'https://example.test/api/',
  );

  test('customer API client builds Laravel API URLs and query strings',
      () async {
    final transport = _FakeTransport(
      const ApiRawResponse(statusCode: 200, body: '{"success":true,"data":{}}'),
    );
    final client = ApiClient(config, transport: transport);

    await client
        .getJson('/v1/system/config', query: const {'platform': 'android'});

    expect(
      transport.lastUri.toString(),
      'https://example.test/api/v1/system/config?platform=android',
    );
  });

  test('customer API client sends bearer token only when requested', () async {
    final transport = _FakeTransport(
      const ApiRawResponse(statusCode: 200, body: '{"success":true}'),
    );
    final client = ApiClient(
      config,
      transport: transport,
      tokenProvider: () async => 'abc123',
    );

    await client.getJson('/v1/customer/profile', authenticated: true);
    expect(transport.lastHeaders?['Authorization'], 'Bearer abc123');
  });

  test('customer API client normalizes Laravel errors', () async {
    final transport = _FakeTransport(
      const ApiRawResponse(
        statusCode: 422,
        body:
            '{"success":false,"message":"Invalid input.","errors":{"phone":["Required"]}}',
      ),
    );
    final client = ApiClient(config, transport: transport);

    await expectLater(
      client.postJson('/v1/customer/login'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having((error) => error.message, 'message', 'Invalid input.'),
      ),
    );
  });
}
