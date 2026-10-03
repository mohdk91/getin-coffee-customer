import 'package:flutter/foundation.dart';

import 'app_environment.dart';

class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final Duration requestTimeout;
  final String googleServerClientId;
  final String googleIosClientId;
  final String appleServiceId;
  final String appleRedirectUri;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.requestTimeout = const Duration(seconds: 20),
    this.googleServerClientId = '',
    this.googleIosClientId = '',
    this.appleServiceId = '',
    this.appleRedirectUri = '',
  });

  factory AppConfig.fromEnvironment() {
    const environmentValue = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'dev',
    );
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    const timeoutSeconds = int.fromEnvironment(
      'API_TIMEOUT_SECONDS',
      defaultValue: 20,
    );
    const googleServerClientId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '',
    );
    const googleIosClientId = String.fromEnvironment(
      'GOOGLE_IOS_CLIENT_ID',
      defaultValue: '',
    );
    const appleServiceId = String.fromEnvironment(
      'APPLE_SERVICE_ID',
      defaultValue: '',
    );
    const appleRedirectUri = String.fromEnvironment(
      'APPLE_REDIRECT_URI',
      defaultValue: '',
    );

    return AppConfig(
      environment: AppEnvironment.parse(environmentValue),
      apiBaseUrl: apiBaseUrl.trim(),
      requestTimeout: const Duration(
        seconds: timeoutSeconds > 0 ? timeoutSeconds : 20,
      ),
      googleServerClientId: googleServerClientId.trim(),
      googleIosClientId: googleIosClientId.trim(),
      appleServiceId: appleServiceId.trim(),
      appleRedirectUri: appleRedirectUri.trim(),
    );
  }

  bool get isApiConfigured => apiBaseUrl.isNotEmpty;

  Uri? get apiUri => isApiConfigured ? Uri.tryParse(apiBaseUrl) : null;

  bool get isApiTransportAllowed {
    if (!isApiConfigured) return !requiresApi;
    final uri = apiUri;
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) return false;
    if (!requiresApi) return uri.scheme == 'http' || uri.scheme == 'https';
    return uri.scheme == 'https';
  }

  bool get allowsDemo =>
      environment == AppEnvironment.development && !kReleaseMode;

  bool get isProduction => environment == AppEnvironment.production;

  bool get requiresApi => !allowsDemo;

  bool get googleSignInConfigured => googleServerClientId.isNotEmpty;

  bool get appleAndroidSignInConfigured {
    final uri = Uri.tryParse(appleRedirectUri);
    return appleServiceId.isNotEmpty &&
        uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty;
  }

  String get environmentBadge => environment.key.toUpperCase();
}
