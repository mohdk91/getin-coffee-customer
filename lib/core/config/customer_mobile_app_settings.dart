import 'package:flutter/foundation.dart';

import '../data/customer_repository.dart';

class CustomerMobileAppSettings {
  final bool firebaseEnabled;
  final bool firebaseAndroidConfigured;
  final bool firebaseIosConfigured;
  final bool phoneAuthEnabled;
  final bool googleAuthEnabled;
  final bool appleAuthEnabled;
  final bool passwordEnabled;
  final String defaultMethod;
  final int otpResendSeconds;

  const CustomerMobileAppSettings({
    required this.firebaseEnabled,
    required this.firebaseAndroidConfigured,
    required this.firebaseIosConfigured,
    required this.phoneAuthEnabled,
    required this.googleAuthEnabled,
    required this.appleAuthEnabled,
    required this.passwordEnabled,
    required this.defaultMethod,
    required this.otpResendSeconds,
  });

  const CustomerMobileAppSettings.safeDefaults()
      : firebaseEnabled = false,
        firebaseAndroidConfigured = false,
        firebaseIosConfigured = false,
        phoneAuthEnabled = false,
        googleAuthEnabled = false,
        appleAuthEnabled = false,
        passwordEnabled = true,
        defaultMethod = 'otp',
        otpResendSeconds = 30;

  bool get firebasePlatformConfigured =>
      firebaseAndroidConfigured || firebaseIosConfigured;

  factory CustomerMobileAppSettings.fromJson(Map<String, dynamic> json) {
    final authentication = _map(json['authentication']);
    final firebase = _map(json['firebase']);
    final otp = _map(authentication['otp']);
    final password = _map(authentication['password']);
    final google = _map(authentication['google']);
    final apple = _map(authentication['apple']);
    final android = _map(firebase['android']);
    final ios = _map(firebase['ios']);
    final providers = _map(firebase['providers']);

    final firebaseEnabled = firebase['enabled'] == true;
    final androidConfigured = android['configured'] == true;
    final iosConfigured = ios['configured'] == true;
    final platformConfigured = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => iosConfigured,
      TargetPlatform.android => androidConfigured,
      _ => false,
    };
    final phoneEnabled = authentication['otp'] is Map && otp['enabled'] == true;
    final googleEnabled = google['enabled'] == true;
    final appleEnabled = apple['enabled'] == true;

    return CustomerMobileAppSettings(
      firebaseEnabled: firebaseEnabled,
      firebaseAndroidConfigured: androidConfigured,
      firebaseIosConfigured: iosConfigured,
      phoneAuthEnabled: firebaseEnabled &&
          platformConfigured &&
          phoneEnabled &&
          providers['phone'] == true,
      googleAuthEnabled: firebaseEnabled &&
          platformConfigured &&
          googleEnabled &&
          providers['google'] == true,
      appleAuthEnabled: firebaseEnabled &&
          platformConfigured &&
          appleEnabled &&
          providers['apple'] == true,
      passwordEnabled: password['enabled'] != false,
      defaultMethod: authentication['default_method']?.toString() == 'password'
          ? 'password'
          : 'otp',
      otpResendSeconds: _positiveInt(otp['resend_seconds'], fallback: 30),
    );
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static int _positiveInt(Object? value, {required int fallback}) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return parsed != null && parsed > 0 ? parsed : fallback;
  }
}

class CustomerMobileAppSettingsStore {
  CustomerMobileAppSettingsStore._();

  static final CustomerMobileAppSettingsStore instance =
      CustomerMobileAppSettingsStore._();

  CustomerMobileAppSettings _settings =
      const CustomerMobileAppSettings.safeDefaults();

  CustomerMobileAppSettings get settings => _settings;

  static Future<void> initialize(CustomerRepositoryContext context) async {
    if (!context.usesApi) {
      instance._settings = const CustomerMobileAppSettings(
        firebaseEnabled: true,
        firebaseAndroidConfigured: true,
        firebaseIosConfigured: true,
        phoneAuthEnabled: true,
        googleAuthEnabled: true,
        appleAuthEnabled: false,
        passwordEnabled: true,
        defaultMethod: 'otp',
        otpResendSeconds: 30,
      );
      return;
    }

    try {
      final payload = await context.apiClient.getJson(
        '/v1/customer/app-config',
      );
      final raw = payload['data'];
      if (raw is Map) {
        instance._settings = CustomerMobileAppSettings.fromJson(
          Map<String, dynamic>.from(raw),
        );
      } else {
        instance._settings = const CustomerMobileAppSettings.safeDefaults();
      }
    } catch (_) {
      // Authentication must fail closed when remote feature flags cannot be
      // loaded. Password login remains available as the recovery path.
      instance._settings = const CustomerMobileAppSettings.safeDefaults();
    }
  }
}
