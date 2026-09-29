import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/customer/customer_country.dart';

void main() {
  group('CustomerCountry flagEmoji', () {
    test('builds Egypt flag from EG', () {
      const country = CustomerCountry(isoCode: 'EG', name: 'Egypt');
      expect(country.flagEmoji, '🇪🇬');
    });

    test('normalizes lowercase ISO country codes', () {
      const country = CustomerCountry(isoCode: 'us', name: 'United States');
      expect(country.flagEmoji, '🇺🇸');
    });

    test('falls back safely for an invalid country code', () {
      const country = CustomerCountry(isoCode: '', name: 'Unknown');
      expect(country.flagEmoji, '🌐');
    });
  });
}
