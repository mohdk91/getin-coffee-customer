import '../../features/cart/cart_controller.dart';
import '../../features/orders/orders_screen.dart';
import '../addresses/customer_address_repository.dart';
import '../addresses/customer_address_store.dart';
import '../auth/customer_account_sync.dart';
import '../auth/customer_auth_store.dart';
import '../catalog/customer_catalog_store.dart';
import '../chat/customer_chat_store.dart';
import '../config/app_config.dart';
import '../content/mobile_app_content_store.dart';
import '../customer/customer_country.dart';
import '../customer/customer_personal_info_store.dart';
import '../customer/customer_profile_photo_store.dart';
import '../favorites/customer_favorites_repository.dart';
import '../favorites/customer_favorites_store.dart';
import '../gift_cards/customer_gift_card_store.dart';
import '../membership/customer_membership_store.dart';
import '../notifications/customer_notifications_store.dart';
import '../payments/customer_payment_method_store.dart';
import '../referrals/customer_referral_store.dart';
import '../reviews/customer_review_store.dart';
import '../rewards/customer_play_store.dart';
import '../rewards/customer_rewards_store.dart';
import '../rewards/customer_stamp_card_store.dart';
import '../settings/customer_preferences_repository.dart';
import '../settings/customer_settings_store.dart';
import '../vouchers/customer_voucher_store.dart';

class CustomerAppBootstrap {
  CustomerAppBootstrap._();

  static final CustomerAppBootstrap instance = CustomerAppBootstrap._();

  AppConfig? _config;
  Future<void>? _future;

  Future<void> start(AppConfig config) {
    _config = config;
    return _future ??= _bootstrap(config);
  }

  Future<void> get ready {
    final future = _future;
    if (future == null) {
      throw StateError('Customer app bootstrap has not started.');
    }
    return future;
  }

  Future<void> retry() {
    final config = _config;
    if (config == null) {
      throw StateError('Customer app bootstrap has no configuration.');
    }
    _future = _bootstrap(config);
    return _future!;
  }

  Future<void> _bootstrap(AppConfig config) async {
    await CustomerAuthStore.initialize(config);
    final context = CustomerAuthStore.instance.context;

    await Future.wait<void>([
      _bestEffort(() => CustomerCatalogStore.initialize(context)),
      _bestEffort(() => MobileAppContentStore.initialize(context)),
      _bestEffort(CustomerCountryStore.initialize),
      _bestEffort(() => CustomerChatStore.initialize(context)),
      _bestEffort(
        () => CustomerAddressStore.initialize(
          repository: CustomerAddressRepository(context),
        ),
      ),
      _bestEffort(CustomerPersonalInfoStore.initialize),
      _bestEffort(CustomerProfilePhotoStore.initialize),
      _bestEffort(
        () => CustomerFavoritesStore.initialize(
          repository: CustomerFavoritesRepository(context),
        ),
      ),
      _bestEffort(() => CustomerGiftCardStore.initialize(context)),
      _bestEffort(() => CustomerMembershipStore.initialize(context)),
      _bestEffort(() => CustomerPaymentMethodStore.initialize(context)),
      _bestEffort(() => CustomerNotificationsStore.initialize(context)),
      _bestEffort(() => CustomerRewardsStore.initialize(context)),
      _bestEffort(() => CustomerPlayStore.initialize(context)),
      _bestEffort(() => CustomerStampCardStore.initialize(context)),
      _bestEffort(
        () => CustomerSettingsStore.initialize(
          repository: CustomerPreferencesRepository(context),
        ),
      ),
      _bestEffort(() => CustomerReferralStore.initialize(context)),
      _bestEffort(() => CustomerVoucherStore.initialize(context)),
      _bestEffort(() => CustomerReviewStore.initialize(context)),
      _bestEffort(() => CustomerOrdersController.initialize(context)),
      _bestEffort(CartController.initialize),
    ]);

    await _bestEffort(CustomerAccountSync.refreshAfterAuthentication);
  }
}

Future<void> _bestEffort(Future<void> Function() action) async {
  try {
    await action();
  } catch (_) {
    // Individual repositories retry on their own screens. Recoverable data
    // refresh failures must not stop startup or hide the video splash.
  }
}
