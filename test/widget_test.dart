import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/app.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';

void main() {
  test('GetinCoffeeApp can be created', () {
    const app = GetinCoffeeApp(
      config: AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: '',
      ),
    );

    expect(
      app,
      isA<GetinCoffeeApp>(),
    );
  });
}
