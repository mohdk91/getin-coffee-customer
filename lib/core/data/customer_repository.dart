import '../config/app_config.dart';
import '../config/app_environment.dart';
import '../network/api_client.dart';
import '../storage/secure_store.dart';

enum CustomerDataSource { demo, api }

class CustomerRepositoryContext {
  final AppConfig config;
  final SecureStore secureStore;
  final ApiClient apiClient;

  const CustomerRepositoryContext._({
    required this.config,
    required this.secureStore,
    required this.apiClient,
  });

  factory CustomerRepositoryContext({
    required AppConfig config,
    SecureStore? secureStore,
    ApiClient? apiClient,
  }) {
    final resolvedStore = secureStore ?? const FlutterSecureStoreAdapter();
    final resolvedApiClient = apiClient ??
        ApiClient(
          config,
          tokenProvider: () => resolvedStore.read(SecureStoreKeys.accessToken),
        );

    return CustomerRepositoryContext._(
      config: config,
      secureStore: resolvedStore,
      apiClient: resolvedApiClient,
    );
  }

  CustomerDataSource get source {
    if (config.isApiConfigured) return CustomerDataSource.api;
    if (config.environment == AppEnvironment.development) {
      return CustomerDataSource.demo;
    }
    throw StateError(
      'API_BASE_URL must be configured for staging and production builds.',
    );
  }

  bool get usesApi => source == CustomerDataSource.api;
}
