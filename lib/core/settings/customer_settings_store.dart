import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/customer_auth_store.dart';
import 'customer_preferences_repository.dart';

@immutable
class CustomerSupportRequest {
  final String id;
  final String topic;
  final String message;
  final DateTime createdAt;
  final String status;
  final String? contextId;
  final String? contextLabel;
  final String? issueType;

  const CustomerSupportRequest({
    required this.id,
    required this.topic,
    required this.message,
    required this.createdAt,
    this.status = 'Open',
    this.contextId,
    this.contextLabel,
    this.issueType,
  });

  String get contextSummary {
    final parts = <String>[
      if (contextLabel != null && contextLabel!.trim().isNotEmpty)
        contextLabel!.trim(),
      if (issueType != null && issueType!.trim().isNotEmpty) issueType!.trim(),
    ];
    return parts.join(' · ');
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'topic': topic,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'contextId': contextId,
        'contextLabel': contextLabel,
        'issueType': issueType,
      };

  factory CustomerSupportRequest.fromJson(Map<String, dynamic> json) {
    return CustomerSupportRequest(
      id: json['id'] as String? ?? '',
      topic: json['topic'] as String? ?? 'Other',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? 'Open',
      contextId: json['contextId'] as String?,
      contextLabel: json['contextLabel'] as String?,
      issueType: json['issueType'] as String?,
    );
  }
}

/// Local/demo settings state for Task #16.
///
/// Laravel/auth/push-provider integrations can later replace the persistence
/// layer without changing the settings screens' public behavior.
class CustomerSettingsStore extends ChangeNotifier {
  CustomerSettingsStore._();

  static final CustomerSettingsStore instance = CustomerSettingsStore._();

  static const _phoneKey = 'getin_demo_settings_phone_v1';
  static const _emailKey = 'getin_demo_settings_email_v1';
  static const _languageKey = 'getin_demo_settings_language_v1';
  static const _appearanceKey = 'getin_demo_settings_appearance_v1';
  static const _notificationsKey = 'getin_demo_settings_notifications_v1';
  static const _biometricKey = 'getin_demo_settings_biometric_v1';
  static const _locationKey = 'getin_demo_settings_location_v1';
  static const _recommendationsKey = 'getin_demo_settings_recommendations_v1';
  static const _marketingKey = 'getin_demo_settings_marketing_v1';
  static const _analyticsKey = 'getin_demo_settings_analytics_v1';
  static const _otherSessionKey = 'getin_demo_settings_other_session_v1';
  static const _passwordChangedKey = 'getin_demo_settings_password_changed_v1';
  static const _dataExportKey = 'getin_demo_settings_data_export_v1';
  static const _deleteRequestedKey = 'getin_demo_settings_delete_requested_v1';
  static const _supportRequestsKey = 'getin_demo_settings_support_requests_v1';

  static const List<String> notificationKeys = <String>[
    'Order status',
    'Driver updates',
    'Stars & rewards',
    'Voucher expiry',
    'Offers & promotions',
    'New products',
    'Member-only offers',
    'Security alerts',
    'Payment alerts',
  ];

  String _phone = '+20 10 0000 0000';
  String _email = 'mohammed@example.com';
  String _language = 'English';
  String _appearance = 'System Default';
  final Map<String, bool> _notifications = <String, bool>{};
  bool _biometricLogin = false;
  bool _locationAccess = true;
  bool _personalizedRecommendations = true;
  bool _marketingPersonalization = true;
  bool _analytics = true;
  bool _otherDemoSessionActive = true;
  DateTime? _lastPasswordChangedAt;
  DateTime? _lastDataExportAt;
  DateTime? _deleteRequestedAt;
  final List<CustomerSupportRequest> _supportRequests =
      <CustomerSupportRequest>[];
  CustomerPreferencesRepository? _preferencesRepository;
  bool _inAppNotificationsEnabled = true;

  bool get usesApi => _preferencesRepository?.usesApi ?? false;
  bool get inAppNotificationsEnabled => _inAppNotificationsEnabled;

  String get phone => _phone;
  String get email => _email;
  String get language => _language;
  String get appearance => _appearance;
  Map<String, bool> get notifications => Map.unmodifiable(_notifications);
  bool get biometricLogin => _biometricLogin;
  bool get locationAccess => _locationAccess;
  bool get personalizedRecommendations => _personalizedRecommendations;
  bool get marketingPersonalization => _marketingPersonalization;
  bool get analytics => _analytics;
  bool get otherDemoSessionActive => _otherDemoSessionActive;
  DateTime? get lastPasswordChangedAt => _lastPasswordChangedAt;
  DateTime? get lastDataExportAt => _lastDataExportAt;
  DateTime? get deleteRequestedAt => _deleteRequestedAt;
  List<CustomerSupportRequest> get supportRequests =>
      List.unmodifiable(_supportRequests);

  int get enabledNotificationCount =>
      _notifications.values.where((enabled) => enabled).length;

  static Future<void> initialize({
    CustomerPreferencesRepository? repository,
  }) async {
    instance._preferencesRepository = repository;
    await instance._load();
    if (repository?.usesApi == true &&
        CustomerAuthStore.instance.isAuthenticated) {
      await instance.refreshFromApi();
    }
  }

  Future<void> refreshFromApi() async {
    final repository = _preferencesRepository;
    if (repository == null || !repository.usesApi ||
        !CustomerAuthStore.instance.isAuthenticated) {
      return;
    }
    final preferences = await repository.fetch();
    _language = preferences.language == 'ar' ? 'العربية' : 'English';
    _inAppNotificationsEnabled = preferences.inAppNotificationsEnabled;
    for (final key in notificationKeys) {
      _notifications[key] = preferences.pushNotificationsEnabled;
    }
    for (final key in const <String>[
      'Offers & promotions',
      'New products',
      'Member-only offers',
    ]) {
      _notifications[key] = preferences.marketingNotificationsEnabled;
    }
    await _saveCorePreferences();
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _phone = prefs.getString(_phoneKey) ?? '+20 10 0000 0000';
    _email = prefs.getString(_emailKey) ?? 'mohammed@example.com';
    _language = prefs.getString(_languageKey) ?? 'English';
    _appearance = prefs.getString(_appearanceKey) ?? 'System Default';
    _biometricLogin = prefs.getBool(_biometricKey) ?? false;
    _locationAccess = prefs.getBool(_locationKey) ?? true;
    _personalizedRecommendations = prefs.getBool(_recommendationsKey) ?? true;
    _marketingPersonalization = prefs.getBool(_marketingKey) ?? true;
    _analytics = prefs.getBool(_analyticsKey) ?? true;
    _otherDemoSessionActive = prefs.getBool(_otherSessionKey) ?? true;
    _lastPasswordChangedAt = _dateFromPrefs(prefs, _passwordChangedKey);
    _lastDataExportAt = _dateFromPrefs(prefs, _dataExportKey);
    _deleteRequestedAt = _dateFromPrefs(prefs, _deleteRequestedKey);

    _notifications
      ..clear()
      ..addEntries(
        notificationKeys.map((key) => MapEntry(key, true)),
      );
    final rawNotifications = prefs.getString(_notificationsKey);
    if (rawNotifications != null) {
      try {
        final decoded = jsonDecode(rawNotifications);
        if (decoded is Map) {
          for (final key in notificationKeys) {
            final saved = decoded[key];
            if (saved is bool) {
              _notifications[key] = saved;
            }
          }
        }
      } catch (_) {
        // Keep the demo defaults if local storage is malformed.
      }
    }

    _supportRequests
      ..clear()
      ..addAll(_decodeSupportRequests(prefs.getString(_supportRequestsKey)));
    notifyListeners();
  }

  Future<void> setPhone(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }
    _phone = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, normalized);
    notifyListeners();
  }

  Future<void> setEmail(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }
    _email = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, normalized);
    notifyListeners();
  }

  static const Set<String> supportedLanguages = <String>{
    'English',
    'العربية',
    'Français',
    'Español',
    'Italiano',
    'Türkçe',
    '简体中文',
  };

  Set<String> get availableLanguages => usesApi
      ? const <String>{'English', 'العربية'}
      : supportedLanguages;

  Future<void> setLanguage(String value) async {
    if (!availableLanguages.contains(value)) return;
    final repository = _preferencesRepository;
    if (repository != null && repository.usesApi) {
      final result = await repository.update(<String, dynamic>{
        'language': value == 'العربية' ? 'ar' : 'en',
      });
      _language = result.language == 'ar' ? 'العربية' : 'English';
    } else {
      _language = value;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _language);
    notifyListeners();
  }

  Future<void> setAppearance(String value) async {
    const supported = <String>{'System Default', 'Light', 'Dark'};
    if (!supported.contains(value)) {
      return;
    }
    _appearance = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appearanceKey, value);
    notifyListeners();
  }

  Future<void> setNotification(String key, bool value) async {
    if (!notificationKeys.contains(key)) return;
    _notifications[key] = value;
    final repository = _preferencesRepository;
    if (repository != null && repository.usesApi) {
      final isMarketing = const <String>{
        'Offers & promotions',
        'New products',
        'Member-only offers',
      }.contains(key);
      await repository.update(<String, dynamic>{
        isMarketing
            ? 'marketing_notifications_enabled'
            : 'push_notifications_enabled': value,
      });
    }
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> setBiometricLogin(bool value) async {
    _biometricLogin = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);
    notifyListeners();
  }

  Future<void> setLocationAccess(bool value) async {
    _locationAccess = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationKey, value);
    notifyListeners();
  }

  Future<void> setPersonalizedRecommendations(bool value) async {
    _personalizedRecommendations = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_recommendationsKey, value);
    notifyListeners();
  }

  Future<void> setMarketingPersonalization(bool value) async {
    _marketingPersonalization = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_marketingKey, value);
    notifyListeners();
  }

  Future<void> setAnalytics(bool value) async {
    _analytics = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsKey, value);
    notifyListeners();
  }

  Future<void> signOutOtherDemoSessions() async {
    _otherDemoSessionActive = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_otherSessionKey, false);
    notifyListeners();
  }

  Future<void> markPasswordChanged() async {
    _lastPasswordChangedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _passwordChangedKey,
      _lastPasswordChangedAt!.toIso8601String(),
    );
    notifyListeners();
  }

  Future<void> requestDataExport() async {
    _lastDataExportAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _dataExportKey,
      _lastDataExportAt!.toIso8601String(),
    );
    notifyListeners();
  }

  Future<void> requestDeleteAccount() async {
    _deleteRequestedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _deleteRequestedKey,
      _deleteRequestedAt!.toIso8601String(),
    );
    notifyListeners();
  }

  Future<CustomerSupportRequest> addSupportRequest({
    required String topic,
    required String message,
    String? contextId,
    String? contextLabel,
    String? issueType,
  }) async {
    final request = CustomerSupportRequest(
      id: 'GET-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      topic: topic,
      message: message.trim(),
      createdAt: DateTime.now(),
      contextId: contextId?.trim().isEmpty == true ? null : contextId?.trim(),
      contextLabel:
          contextLabel?.trim().isEmpty == true ? null : contextLabel?.trim(),
      issueType: issueType?.trim().isEmpty == true ? null : issueType?.trim(),
    );
    _supportRequests.insert(0, request);
    await _saveSupportRequests();
    notifyListeners();
    return request;
  }

  Future<void> _saveCorePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _language);
    await _saveNotifications();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, jsonEncode(_notifications));
  }

  Future<void> _saveSupportRequests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _supportRequestsKey,
      jsonEncode(_supportRequests.map((item) => item.toJson()).toList()),
    );
  }

  List<CustomerSupportRequest> _decodeSupportRequests(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <CustomerSupportRequest>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <CustomerSupportRequest>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => CustomerSupportRequest.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList();
    } catch (_) {
      return <CustomerSupportRequest>[];
    }
  }

  DateTime? _dateFromPrefs(SharedPreferences prefs, String key) {
    return DateTime.tryParse(prefs.getString(key) ?? '');
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in <String>[
      _phoneKey,
      _emailKey,
      _languageKey,
      _appearanceKey,
      _notificationsKey,
      _biometricKey,
      _locationKey,
      _recommendationsKey,
      _marketingKey,
      _analyticsKey,
      _otherSessionKey,
      _passwordChangedKey,
      _dataExportKey,
      _deleteRequestedKey,
      _supportRequestsKey,
    ]) {
      await prefs.remove(key);
    }
    await _load();
  }
}
