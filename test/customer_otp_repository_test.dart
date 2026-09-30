import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/data/customer_repository.dart';
import 'package:getin_coffee/core/storage/secure_store.dart';
import 'package:getin_coffee/core/auth/customer_account_repository.dart';

void main() {
  test('Task 19 demo OTP verifies the authenticated customer', () async {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    );
    final repository = CustomerAccountRepository(
      CustomerRepositoryContext(
        config: config,
        secureStore: MemorySecureStore(),
      ),
    );
    final registered = await repository.register(
      name: 'OTP Customer',
      email: 'otp@example.com',
      phone: '+201000000002',
      password: 'Password123',
      passwordConfirmation: 'Password123',
    );
    expect(registered.customer.phoneVerified, isFalse);
    await repository.sendOtp();
    final verified = await repository.verifyOtp('123456');
    expect(verified.phoneVerified, isTrue);
  });
}
