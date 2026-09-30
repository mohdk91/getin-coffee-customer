import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/data/customer_repository.dart';
import 'package:getin_coffee/core/storage/secure_store.dart';

void main() {
  test('configured development builds use API source', () {
    final context = CustomerRepositoryContext(
      config: const AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: 'https://example.test/api',
      ),
      secureStore: MemorySecureStore(),
    );

    expect(context.source, CustomerDataSource.api);
  });

  test('unconfigured development builds keep explicit demo source', () {
    final context = CustomerRepositoryContext(
      config: const AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: '',
      ),
      secureStore: MemorySecureStore(),
    );

    expect(context.source, CustomerDataSource.demo);
  });

  test('production builds never silently fall back to demo data', () {
    final context = CustomerRepositoryContext(
      config: const AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: '',
      ),
      secureStore: MemorySecureStore(),
    );

    expect(() => context.source, throwsStateError);
  });
}
