import '../addresses/customer_address_store.dart';
import '../customer/customer_country.dart';
import '../customer/customer_personal_info_store.dart';
import '../settings/customer_settings_store.dart';
import 'customer_auth_store.dart';

abstract final class CustomerAccountSync {
  static Future<void> refreshAfterAuthentication() async {
    final auth = CustomerAuthStore.instance;
    final account = auth.customer;
    if (account == null) return;

    final country = CustomerCountryCatalog.byIsoCode(account.countryCode);
    if (country != null) {
      await CustomerCountryStore.setCountry(country);
    }
    final gender = switch (account.gender) {
      'male' => 'Male',
      'female' => 'Female',
      _ => 'Prefer not to say',
    };
    await CustomerPersonalInfoStore.setGender(gender);

    if (!auth.usesApi) return;
    try {
      await CustomerAddressStore.instance.refreshFromApi();
    } catch (_) {
      // Account login remains valid when address refresh is temporarily offline.
    }
    try {
      await CustomerSettingsStore.instance.refreshFromApi();
    } catch (_) {
      // Preferences can refresh on the next settings visit.
    }
  }
}
