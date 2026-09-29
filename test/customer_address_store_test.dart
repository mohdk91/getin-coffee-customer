import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/addresses/customer_address_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await CustomerAddressStore.instance.resetForTesting();
  });

  test('adds an address and makes the first address default', () async {
    await CustomerAddressStore.instance.addAddress(
      const CustomerAddress(
        id: 'test-home',
        label: 'Home',
        area: 'Stanley',
        city: 'Alexandria',
        building: '12',
        floor: '4',
        apartment: '8',
        deliveryInstructions: 'Call on arrival',
        latitude: 31.2,
        longitude: 29.9,
        isDefault: false,
      ),
    );

    expect(CustomerAddressStore.instance.addresses, hasLength(1));
    expect(CustomerAddressStore.instance.defaultAddress?.id, 'test-home');
    expect(CustomerAddressStore.instance.checkoutAddress?.id, 'test-home');
  });

  test('setDefault also selects the address for checkout', () async {
    await CustomerAddressStore.instance.addAddress(
      const CustomerAddress(
        id: 'one',
        label: 'Home',
        area: 'Stanley',
        city: 'Alexandria',
        building: '1',
        floor: '',
        apartment: '',
        deliveryInstructions: '',
        latitude: 31.2,
        longitude: 29.9,
        isDefault: false,
      ),
    );
    await CustomerAddressStore.instance.addAddress(
      const CustomerAddress(
        id: 'two',
        label: 'Work',
        area: 'Smouha',
        city: 'Alexandria',
        building: '2',
        floor: '',
        apartment: '',
        deliveryInstructions: '',
        latitude: 31.21,
        longitude: 29.94,
        isDefault: false,
      ),
    );

    await CustomerAddressStore.instance.setDefault('two');

    expect(CustomerAddressStore.instance.defaultAddress?.id, 'two');
    expect(CustomerAddressStore.instance.checkoutAddress?.id, 'two');
  });

  test('address JSON round trip preserves delivery fields', () {
    const address = CustomerAddress(
      id: 'json',
      label: 'Other',
      area: 'Roushdy',
      city: 'Alexandria',
      building: '9',
      floor: '3',
      apartment: '7',
      deliveryInstructions: 'Do not ring',
      latitude: 31.23,
      longitude: 29.96,
      isDefault: true,
    );

    final decoded = CustomerAddress.fromJson(address.toJson());
    expect(decoded.label, 'Other');
    expect(decoded.details, 'Building 9 · Floor 3 · Apt 7');
    expect(decoded.deliveryInstructions, 'Do not ring');
    expect(decoded.isDefault, isTrue);
  });
}
