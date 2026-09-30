import '../auth/customer_account_models.dart';
import '../data/customer_repository.dart';
import '../network/api_exception.dart';
import 'customer_address_store.dart';

class CustomerAddressRepository {
  final CustomerRepositoryContext context;

  const CustomerAddressRepository(this.context);

  bool get usesApi => context.usesApi;

  Future<List<CustomerAddress>> list() async {
    if (!usesApi) return const <CustomerAddress>[];
    final payload = await context.apiClient.getJson(
      '/v1/customer/addresses',
      authenticated: true,
    );
    final data = payload['data'];
    if (data is! List) {
      throw const ApiException('The GETIN API returned invalid address data.');
    }
    return data
        .whereType<Map>()
        .map((item) => _fromApi(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<CustomerAddress> create(
    CustomerAddress address, {
    required CustomerAccount account,
  }) async {
    if (!usesApi) return address;
    final payload = await context.apiClient.requestJson(
      'POST',
      '/v1/customer/addresses',
      authenticated: true,
      body: _toApi(address, account: account),
    );
    return _fromApi(_dataMap(payload));
  }

  Future<CustomerAddress> update(
    CustomerAddress address, {
    required CustomerAccount account,
  }) async {
    if (!usesApi) return address;
    final payload = await context.apiClient.requestJson(
      'PATCH',
      '/v1/customer/addresses/${address.id}',
      authenticated: true,
      body: _toApi(address, account: account),
    );
    return _fromApi(_dataMap(payload));
  }

  Future<CustomerAddress> setDefault(String id) async {
    final payload = await context.apiClient.requestJson(
      'PUT',
      '/v1/customer/addresses/$id/default',
      authenticated: true,
    );
    return _fromApi(_dataMap(payload));
  }

  Future<void> delete(String id) async {
    await context.apiClient.requestJson(
      'DELETE',
      '/v1/customer/addresses/$id',
      authenticated: true,
    );
  }

  Map<String, dynamic> _toApi(
    CustomerAddress address, {
    required CustomerAccount account,
  }) {
    return <String, dynamic>{
      'label': address.label.trim().isEmpty ? 'Home' : address.label.trim(),
      'recipient_name': account.name.trim().isEmpty ? 'GETIN Customer' : account.name.trim(),
      'phone': account.phone.trim(),
      'address_line_1': address.building.trim().isEmpty ? address.title : address.building.trim(),
      'address_line_2': _encodeDetails(address),
      'city': address.city.trim(),
      'area': address.area.trim().isEmpty ? null : address.area.trim(),
      'country_code': account.countryCode,
      'latitude': address.latitude,
      'longitude': address.longitude,
      'is_default': address.isDefault,
    };
  }

  String? _encodeDetails(CustomerAddress address) {
    final parts = <String>[
      if (address.floor.trim().isNotEmpty) 'Floor ${address.floor.trim()}',
      if (address.apartment.trim().isNotEmpty) 'Apt ${address.apartment.trim()}',
      if (address.deliveryInstructions.trim().isNotEmpty)
        'Note ${address.deliveryInstructions.trim()}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  CustomerAddress _fromApi(Map<String, dynamic> json) {
    final details = json['address_line_2']?.toString() ?? '';
    return CustomerAddress(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Home',
      area: json['area']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      building: json['address_line_1']?.toString() ?? '',
      floor: _detailValue(details, 'Floor '),
      apartment: _detailValue(details, 'Apt '),
      deliveryInstructions: _detailValue(details, 'Note '),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      isDefault: json['is_default'] == true,
    );
  }

  String _detailValue(String details, String prefix) {
    for (final part in details.split(' · ')) {
      if (part.startsWith(prefix)) return part.substring(prefix.length).trim();
    }
    return '';
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('The GETIN API returned invalid address data.');
  }
}
