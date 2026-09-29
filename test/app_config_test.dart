import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';

void main() {
  test('customer environment parser is deterministic', () {
    expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
    expect(AppEnvironment.parse('PROD'), AppEnvironment.production);
    expect(AppEnvironment.parse('unknown'), AppEnvironment.development);
  });

  test('customer API configuration never invents a backend URL', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    );

    expect(config.isApiConfigured, isFalse);
    expect(config.requestTimeout, const Duration(seconds: 20));
  });
}
