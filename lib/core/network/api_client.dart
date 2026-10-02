import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_retry_policy.dart';
import 'api_transport.dart';

typedef AccessTokenProvider = Future<String?> Function();
typedef ApiRequestIdProvider = String Function();

class ApiClient {
  final AppConfig config;
  final ApiTransport? transport;
  final AccessTokenProvider? tokenProvider;
  final ApiRetryPolicy retryPolicy;
  final ApiRequestIdProvider? requestIdProvider;

  static int _requestSequence = 0;

  const ApiClient(
    this.config, {
    this.transport,
    this.tokenProvider,
    this.retryPolicy = const ApiRetryPolicy(),
    this.requestIdProvider,
  });

  Uri endpoint(String path, {Map<String, Object?> query = const {}}) {
    if (!config.isApiConfigured) {
      throw StateError(
        'API_BASE_URL is not configured. Pass it with --dart-define.',
      );
    }

    if (!config.isApiTransportAllowed) {
      throw StateError(
        'API_BASE_URL must use HTTPS outside development/debug builds.',
      );
    }

    final base = config.apiBaseUrl.endsWith('/')
        ? config.apiBaseUrl.substring(0, config.apiBaseUrl.length - 1)
        : config.apiBaseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    // Older Customer repositories use /v1/... while newer commerce routes use
    // /api/v1/.... Laravel exposes both families under the /api prefix, so
    // normalize only the legacy /v1 paths at the transport boundary.
    final apiPath = cleanPath.startsWith('/v1/') ? '/api$cleanPath' : cleanPath;
    final uri = Uri.parse('$base$apiPath');
    final queryParameters = <String, String>{};

    for (final entry in query.entries) {
      final value = entry.value;
      if (value != null) queryParameters[entry.key] = value.toString();
    }

    return queryParameters.isEmpty
        ? uri
        : uri.replace(queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?> query = const {},
    bool authenticated = false,
  }) {
    return requestJson(
      'GET',
      path,
      query: query,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    Map<String, Object?> query = const {},
    bool authenticated = false,
    bool retryable = false,
  }) {
    return requestJson(
      'POST',
      path,
      query: query,
      body: body,
      authenticated: authenticated,
      retryable: retryable,
    );
  }

  Future<Map<String, dynamic>> requestJson(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
    bool authenticated = false,
    Map<String, String> headers = const {},
    bool? retryable,
  }) async {
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...headers,
    };

    final requestId = _requestIdFromHeaders(requestHeaders) ?? _newRequestId();
    requestHeaders['X-Request-ID'] = requestId;

    if (authenticated) {
      final token = await tokenProvider?.call();
      if (token == null || token.trim().isEmpty) {
        throw const ApiException(
          'Authentication token is unavailable.',
          statusCode: 401,
          kind: ApiFailureKind.authentication,
        );
      }
      requestHeaders['Authorization'] = 'Bearer ${token.trim()}';
    }

    final canRetry = retryable ?? _methodIsSafeToRetry(method);
    final attempts = canRetry ? retryPolicy.maxAttempts : 1;
    Object? lastTransportError;

    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        final response = await (transport ?? const IoApiTransport()).send(
          endpoint(path, query: query),
          method: method.toUpperCase(),
          headers: requestHeaders,
          body: body,
          timeout: config.requestTimeout,
        );

        if (canRetry &&
            attempt < attempts &&
            retryPolicy.shouldRetryStatus(response.statusCode)) {
          await _delayBeforeRetry(attempt + 1);
          continue;
        }

        return _decode(response, requestId: requestId);
      } catch (error) {
        if (error is ApiException) rethrow;
        lastTransportError = error;

        if (!canRetry || attempt >= attempts) {
          break;
        }

        await _delayBeforeRetry(attempt + 1);
      }
    }

    throw _transportFailure(lastTransportError, requestId: requestId);
  }

  bool _methodIsSafeToRetry(String method) {
    return const <String>{'GET', 'HEAD', 'OPTIONS'}
        .contains(method.toUpperCase());
  }

  Future<void> _delayBeforeRetry(int nextAttempt) async {
    final delay = retryPolicy.delayBeforeAttempt(nextAttempt);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  ApiException _transportFailure(Object? error, {required String requestId}) {
    if (error is TimeoutException) {
      return ApiException(
        'The request timed out. Please try again.',
        cause: error,
        kind: ApiFailureKind.timeout,
        requestId: requestId,
      );
    }
    if (error is SocketException) {
      return ApiException(
        'The network is unavailable. Check your connection and try again.',
        cause: error,
        kind: ApiFailureKind.offline,
        requestId: requestId,
      );
    }
    return ApiException(
      'Unable to reach the GETIN API.',
      cause: error,
      kind: ApiFailureKind.unknown,
      requestId: requestId,
    );
  }

  Map<String, dynamic> _decode(
    ApiRawResponse response, {
    required String requestId,
  }) {
    Map<String, dynamic> payload = const <String, dynamic>{};
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        } else if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        } else {
          throw const FormatException('JSON root is not an object.');
        }
      } catch (error) {
        throw ApiException(
          'The GETIN API returned an invalid JSON response.',
          statusCode: response.statusCode,
          cause: error,
          kind: ApiFailureKind.invalidResponse,
          requestId: _responseRequestId(response.headers) ?? requestId,
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final rawErrors = payload['errors'];
      throw ApiException(
        payload['message']?.toString() ?? 'The GETIN API request failed.',
        statusCode: response.statusCode,
        errors: rawErrors is Map
            ? Map<String, dynamic>.from(rawErrors)
            : const <String, dynamic>{},
        kind: _failureKindForStatus(response.statusCode),
        retryAfter: _retryAfter(response.headers),
        requestId: _responseRequestId(response.headers) ?? requestId,
      );
    }

    return payload;
  }


  String _newRequestId() {
    final provided = requestIdProvider?.call().trim();
    if (provided != null && _isValidRequestId(provided)) {
      return provided;
    }

    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final sequence = (++_requestSequence).toRadixString(36);
    return 'mobile-$stamp-$sequence';
  }

  String? _requestIdFromHeaders(Map<String, String> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'x-request-id') {
        final value = entry.value.trim();
        return _isValidRequestId(value) ? value : null;
      }
    }
    return null;
  }

  String? _responseRequestId(Map<String, String> headers) {
    return _requestIdFromHeaders(headers);
  }

  bool _isValidRequestId(String value) {
    return RegExp(r'^[A-Za-z0-9._:-]{8,96}$').hasMatch(value);
  }

  ApiFailureKind _failureKindForStatus(int statusCode) {
    return switch (statusCode) {
      401 => ApiFailureKind.authentication,
      403 => ApiFailureKind.forbidden,
      404 => ApiFailureKind.notFound,
      408 => ApiFailureKind.timeout,
      409 => ApiFailureKind.conflict,
      422 => ApiFailureKind.validation,
      429 => ApiFailureKind.rateLimited,
      >= 500 => ApiFailureKind.server,
      _ => ApiFailureKind.unknown,
    };
  }

  Duration? _retryAfter(Map<String, String> headers) {
    String? value;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'retry-after') {
        value = entry.value.trim();
        break;
      }
    }
    final seconds = int.tryParse(value ?? '');
    return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
  }
}
