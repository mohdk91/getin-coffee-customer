import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/auth/customer_auth_store.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/storage/secure_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cachedAccount = <String, dynamic>{
    'id': 7,
    'name': 'Restored Customer',
    'email': 'restored@example.com',
    'phone': '+201000000000',
    'language': 'en',
    'status': 'active',
    'email_verified': true,
    'phone_verified': true,
    'gender': 'male',
    'date_of_birth': '1988-02-04',
    'country_code': 'EG',
  };

  test('Task 25 restores secure cached customer when token exists', () async {
    final secure = MemorySecureStore();
    await secure.write(SecureStoreKeys.accessToken, 'demo-token');
    await secure.write(
      SecureStoreKeys.customerAccountCache,
      jsonEncode(cachedAccount),
    );

    await CustomerAuthStore.initialize(
      const AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: '',
      ),
      secureStore: secure,
    );

    expect(CustomerAuthStore.instance.isAuthenticated, isTrue);
    expect(CustomerAuthStore.instance.customer?.name, 'Restored Customer');
    expect(CustomerAuthStore.instance.customer?.countryCode, 'EG');
  });

  test('Task 25 never restores cached identity without a session token', () async {
    final secure = MemorySecureStore();
    await secure.write(
      SecureStoreKeys.customerAccountCache,
      jsonEncode(cachedAccount),
    );

    await CustomerAuthStore.initialize(
      const AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: '',
      ),
      secureStore: secure,
    );

    expect(CustomerAuthStore.instance.isAuthenticated, isFalse);
    expect(CustomerAuthStore.instance.customer, isNull);
  });
}
