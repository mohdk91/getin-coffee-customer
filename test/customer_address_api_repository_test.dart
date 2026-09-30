import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/addresses/customer_address_repository.dart';
import 'package:getin_coffee/core/auth/customer_account_models.dart';
import 'package:getin_coffee/core/config/app_config.dart';
import 'package:getin_coffee/core/config/app_environment.dart';
import 'package:getin_coffee/core/data/customer_repository.dart';
import 'package:getin_coffee/core/network/api_client.dart';
import 'package:getin_coffee/core/network/api_transport.dart';
import 'package:getin_coffee/core/storage/secure_store.dart';

class _AddressTransport implements ApiTransport {
  final List<String> paths = <String>[];
  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    paths.add('$method ${uri.path}');
    final isList = method == 'GET';
    final address = <String, dynamic>{
      'id': 11,
      'label': 'Home',
      'recipient_name': 'GETIN Customer',
      'phone': '+201000000000',
      'address_line_1': '12',
      'address_line_2': 'Floor 4 · Apt 8 · Note Call on arrival',
      'city': 'Alexandria',
      'area': 'Stanley',
      'country_code': 'EG',
      'latitude': 31.2,
      'longitude': 29.9,
      'is_default': true,
    };
    return ApiRawResponse(
      statusCode: method == 'POST' ? 201 : 200,
      body: jsonEncode(<String, dynamic>{
        'success': true,
        'data': isList ? <Map<String, dynamic>>[address] : address,
      }),
    );
  }
}

void main() {
  test('Task 21 maps Laravel customer address CRUD endpoints', () async {
    final transport = _AddressTransport();
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://api.example.com/api',
    );
    final secure = MemorySecureStore();
    await secure.write(SecureStoreKeys.accessToken, 'token');
    final repository = CustomerAddressRepository(
      CustomerRepositoryContext(
        config: config,
        secureStore: secure,
        apiClient: ApiClient(
          config,
          transport: transport,
          tokenProvider: () => secure.read(SecureStoreKeys.accessToken),
        ),
      ),
    );
    const account = CustomerAccount(
      id: 7,
      name: 'GETIN Customer',
      email: 'customer@example.com',
      phone: '+201000000000',
      language: 'en',
      status: 'active',
      emailVerified: true,
      phoneVerified: true,
      countryCode: 'EG',
    );

    final listed = await repository.list();
    expect(listed.single.floor, '4');
    expect(listed.single.apartment, '8');

    final created = await repository.create(
      listed.single.copyWith(id: ''),
      account: account,
    );
    expect(created.id, '11');
    await repository.setDefault('11');
    await repository.delete('11');

    expect(transport.paths, contains('GET /api/v1/customer/addresses'));
    expect(transport.paths, contains('POST /api/v1/customer/addresses'));
    expect(transport.paths, contains('PUT /api/v1/customer/addresses/11/default'));
    expect(transport.paths, contains('DELETE /api/v1/customer/addresses/11'));
  });
}
