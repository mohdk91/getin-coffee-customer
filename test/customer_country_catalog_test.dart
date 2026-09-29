import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/customer/customer_country.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog resolves ISO codes and flags', () {
    final egypt = CustomerCountryCatalog.byIsoCode('eg');
    final saudi = CustomerCountryCatalog.byIsoCode('SA');

    expect(egypt?.name, 'Egypt');
    expect(egypt?.flagEmoji, '🇪🇬');
    expect(saudi?.flagEmoji, '🇸🇦');
    expect(CustomerCountryCatalog.all.length, greaterThan(200));
  });

  test('selected country persists locally', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final france = CustomerCountryCatalog.byIsoCode('FR')!;

    await CustomerCountryStore.setCountry(france);
    CustomerCountryStore.current.value = const CustomerCountry(
      isoCode: 'EG',
      name: 'Egypt',
    );
    await CustomerCountryStore.initialize();

    expect(CustomerCountryStore.current.value.normalizedIsoCode, 'FR');
    expect(CustomerCountryStore.current.value.flagEmoji, '🇫🇷');
  });
}
