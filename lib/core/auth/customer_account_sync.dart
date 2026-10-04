import '../addresses/customer_address_store.dart';
import '../customer/customer_country.dart';
import '../customer/customer_personal_info_store.dart';
import '../membership/customer_membership_store.dart';
import '../notifications/customer_notifications_store.dart';
import '../payments/customer_payment_method_store.dart';
import '../referrals/customer_referral_store.dart';
import '../rewards/customer_play_store.dart';
import '../rewards/customer_rewards_store.dart';
import '../rewards/customer_stamp_card_store.dart';
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

    // These reads are independent. Run them concurrently so authentication
    // does not wait for the sum of every account bootstrap request. Each task
    // remains best-effort; destination screens can retry their own state.
    await Future.wait<void>([
      _bestEffort(CustomerAddressStore.instance.refreshFromApi),
      _bestEffort(CustomerSettingsStore.instance.refreshFromApi),
      _bestEffort(CustomerMembershipStore.instance.refresh),
      _bestEffort(CustomerPaymentMethodStore.instance.refresh),
      _bestEffort(CustomerNotificationsStore.instance.refresh),
      _bestEffort(CustomerRewardsStore.instance.refresh),
      _bestEffort(CustomerStampCardStore.instance.refresh),
      _bestEffort(CustomerPlayStore.instance.refresh),
      _bestEffort(CustomerReferralStore.instance.refresh),
    ]);
  }

  static Future<void> _bestEffort(Future<void> Function() refresh) async {
    try {
      await refresh();
    } catch (_) {
      // Authentication remains valid. The destination screen owns retries.
    }
  }
}
