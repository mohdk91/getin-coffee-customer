import '../data/customer_repository.dart';
import '../network/api_exception.dart';
import 'customer_account_models.dart';

class CustomerAccountRepository {
  final CustomerRepositoryContext context;
  CustomerAccount? _demoCustomer;

  CustomerAccountRepository(this.context);

  bool get usesApi => context.usesApi;

  Future<CustomerAuthResult> login({
    required String identifier,
    required String password,
  }) async {
    final normalizedIdentifier = identifier.trim();
    if (normalizedIdentifier.isEmpty || password.isEmpty) {
      throw const ApiException('Enter your email/mobile number and password.');
    }

    if (!usesApi) {
      final customer = _demoCustomer ??
          CustomerAccount(
            id: 1,
            name: 'GETIN Customer',
            email: normalizedIdentifier.contains('@')
                ? normalizedIdentifier
                : 'customer@getin.local',
            phone: normalizedIdentifier.contains('@')
                ? '+20 10 0000 0000'
                : normalizedIdentifier,
            language: 'en',
            status: 'active',
            emailVerified: true,
            phoneVerified: true,
          );
      _demoCustomer = customer;
      return CustomerAuthResult(customer: customer, token: 'demo-token');
    }

    final payload = await context.apiClient.postJson(
      '/v1/customer/login',
      body: <String, dynamic>{
        'identifier': normalizedIdentifier,
        'password': password,
      },
    );

    final data = _dataObject(payload);
    final customer = _mapObject(data['customer'], field: 'customer');
    final token = data['token']?.toString().trim() ?? '';
    if (token.isEmpty) {
      throw const ApiException('The GETIN API did not return an access token.');
    }

    return CustomerAuthResult(
      customer: CustomerAccount.fromJson(customer),
      token: token,
    );
  }

  Map<String, dynamic> _dataObject(Map<String, dynamic> payload) {
    return _mapObject(payload['data'], field: 'data');
  }

  Map<String, dynamic> _mapObject(Object? value, {required String field}) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ApiException('The GETIN API returned invalid $field data.');
  }
}
