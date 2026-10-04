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
      throw const ApiException(
          'Sign-in could not be completed. Please try again.');
    }

    return CustomerAuthResult(
      customer: CustomerAccount.fromJson(customer),
      token: token,
    );
  }

  Future<CustomerAuthResult> socialLogin({
    required String provider,
    required String identityToken,
    String? nonce,
    String? displayName,
  }) async {
    if (!usesApi) {
      throw const ApiException(
        'Social sign-in is unavailable right now. Please try again.',
      );
    }

    final body = <String, dynamic>{
      'provider': provider,
      'identity_token': identityToken,
      if (nonce != null && nonce.trim().isNotEmpty) 'nonce': nonce.trim(),
      if (displayName != null && displayName.trim().isNotEmpty)
        'display_name': displayName.trim(),
    };
    final payload = await context.apiClient.postJson(
      '/v1/customer/auth/social',
      body: body,
    );
    final data = _dataObject(payload);
    final customer = _mapObject(data['customer'], field: 'customer');
    final token = data['token']?.toString().trim() ?? '';
    if (token.isEmpty) {
      throw const ApiException(
          'Sign-in could not be completed. Please try again.');
    }
    return CustomerAuthResult(
      customer: CustomerAccount.fromJson(customer),
      token: token,
    );
  }

  Future<CustomerAuthResult> firebaseLogin({
    required String idToken,
    String? displayName,
  }) async {
    if (!usesApi) {
      throw const ApiException(
        'This sign-in method is unavailable right now. Please try again.',
      );
    }

    final token = idToken.trim();
    if (token.isEmpty) {
      throw const ApiException('Firebase identity token is unavailable.');
    }

    final payload = await context.apiClient.postJson(
      '/v1/customer/auth/firebase',
      body: <String, dynamic>{
        'id_token': token,
        if (displayName != null && displayName.trim().isNotEmpty)
          'display_name': displayName.trim(),
      },
    );
    final data = _dataObject(payload);
    final customer = _mapObject(data['customer'], field: 'customer');
    final accessToken = data['token']?.toString().trim() ?? '';
    if (accessToken.isEmpty) {
      throw const ApiException(
          'Sign-in could not be completed. Please try again.');
    }
    return CustomerAuthResult(
      customer: CustomerAccount.fromJson(customer),
      token: accessToken,
    );
  }

  Future<CustomerAuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String language = 'en',
    String? referralCode,
  }) async {
    if (!usesApi) {
      final customer = CustomerAccount(
        id: 1,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        language: language,
        status: 'active',
        emailVerified: false,
        phoneVerified: false,
      );
      _demoCustomer = customer;
      return CustomerAuthResult(customer: customer, token: 'demo-token');
    }

    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
      'language': language,
    };
    final referral = referralCode?.trim();
    if (referral != null && referral.isNotEmpty) {
      body['referral_code'] = referral.toUpperCase();
    }

    final payload = await context.apiClient.postJson(
      '/v1/customer/register',
      body: body,
    );
    final data = _dataObject(payload);
    final customer = _mapObject(data['customer'], field: 'customer');
    final token = data['token']?.toString().trim() ?? '';
    if (token.isEmpty) {
      throw const ApiException(
          'Sign-in could not be completed. Please try again.');
    }
    return CustomerAuthResult(
      customer: CustomerAccount.fromJson(customer),
      token: token,
    );
  }

  Future<CustomerAccount> fetchProfile() async {
    if (!usesApi) {
      final current = _demoCustomer;
      if (current == null) {
        throw const ApiException('Please sign in to continue.');
      }
      return current;
    }

    final payload = await context.apiClient.getJson(
      '/v1/customer/profile',
      authenticated: true,
    );
    final data = _dataObject(payload);
    final customer = data.containsKey('customer')
        ? _mapObject(data['customer'], field: 'customer')
        : data;
    return CustomerAccount.fromJson(customer);
  }

  Future<CustomerAccount> updateProfile(Map<String, dynamic> changes) async {
    if (!usesApi) {
      final current = _demoCustomer;
      if (current == null) {
        throw const ApiException('Please sign in to continue.');
      }
      final merged = <String, dynamic>{...current.toJson(), ...changes};
      _demoCustomer = CustomerAccount.fromJson(merged);
      return _demoCustomer!;
    }

    final payload = await context.apiClient.requestJson(
      'PATCH',
      '/v1/customer/profile',
      authenticated: true,
      body: changes,
    );
    final data = _dataObject(payload);
    final customer = data.containsKey('customer')
        ? _mapObject(data['customer'], field: 'customer')
        : data;
    return CustomerAccount.fromJson(customer);
  }

  Future<Map<String, dynamic>> sendOtp({bool resend = false}) async {
    if (!usesApi) {
      return <String, dynamic>{
        'channel': 'phone',
        'purpose': 'phone_verification',
        'destination': '***0000',
        'expires_in_seconds': 300,
        'resend_after_seconds': 30,
      };
    }
    final payload = await context.apiClient.postJson(
      resend ? '/v1/customer/otp/resend' : '/v1/customer/otp/send',
      authenticated: true,
      body: const <String, dynamic>{'purpose': 'phone_verification'},
    );
    return _dataObject(payload);
  }

  Future<CustomerAccount> verifyOtp(String code) async {
    if (!usesApi) {
      final current = _demoCustomer;
      if (current == null) {
        throw const ApiException('Please sign in to continue.');
      }
      if (code.trim().length != 6) {
        throw const ApiException('Enter the complete 6-digit code.');
      }
      _demoCustomer = current.copyWith(phoneVerified: true);
      return _demoCustomer!;
    }
    final payload = await context.apiClient.postJson(
      '/v1/customer/otp/verify',
      authenticated: true,
      body: <String, dynamic>{
        'code': code.trim(),
        'purpose': 'phone_verification',
      },
    );
    final data = _dataObject(payload);
    final customer = _mapObject(data['customer'], field: 'customer');
    return CustomerAccount.fromJson(customer);
  }

  Map<String, dynamic> _dataObject(Map<String, dynamic> payload) {
    return _mapObject(payload['data'], field: 'data');
  }

  Map<String, dynamic> _mapObject(Object? value, {required String field}) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const ApiException(
        'We couldn’t load your account details. Please try again.');
  }
}
