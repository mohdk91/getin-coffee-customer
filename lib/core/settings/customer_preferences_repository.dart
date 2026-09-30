import '../data/customer_repository.dart';
import '../network/api_exception.dart';

class CustomerPreferences {
  final String language;
  final bool marketingNotificationsEnabled;
  final bool pushNotificationsEnabled;
  final bool inAppNotificationsEnabled;

  const CustomerPreferences({
    required this.language,
    required this.marketingNotificationsEnabled,
    required this.pushNotificationsEnabled,
    required this.inAppNotificationsEnabled,
  });

  factory CustomerPreferences.fromJson(Map<String, dynamic> json) {
    return CustomerPreferences(
      language: json['language']?.toString() ?? 'en',
      marketingNotificationsEnabled:
          json['marketing_notifications_enabled'] == true,
      pushNotificationsEnabled: json['push_notifications_enabled'] == true,
      inAppNotificationsEnabled:
          json['in_app_notifications_enabled'] == true,
    );
  }
}

class CustomerPreferencesRepository {
  final CustomerRepositoryContext context;

  const CustomerPreferencesRepository(this.context);

  bool get usesApi => context.usesApi;

  Future<CustomerPreferences> fetch() async {
    if (!usesApi) {
      return const CustomerPreferences(
        language: 'en',
        marketingNotificationsEnabled: true,
        pushNotificationsEnabled: true,
        inAppNotificationsEnabled: true,
      );
    }
    final payload = await context.apiClient.getJson(
      '/v1/customer/preferences',
      authenticated: true,
    );
    return CustomerPreferences.fromJson(_dataMap(payload));
  }

  Future<CustomerPreferences> update(Map<String, dynamic> changes) async {
    if (!usesApi) {
      return CustomerPreferences.fromJson(<String, dynamic>{
        'language': changes['language'] ?? 'en',
        'marketing_notifications_enabled':
            changes['marketing_notifications_enabled'] ?? true,
        'push_notifications_enabled':
            changes['push_notifications_enabled'] ?? true,
        'in_app_notifications_enabled':
            changes['in_app_notifications_enabled'] ?? true,
      });
    }
    final payload = await context.apiClient.requestJson(
      'PATCH',
      '/v1/customer/preferences',
      authenticated: true,
      body: changes,
    );
    return CustomerPreferences.fromJson(_dataMap(payload));
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('The GETIN API returned invalid preference data.');
  }
}
