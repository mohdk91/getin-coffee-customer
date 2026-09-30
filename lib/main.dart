import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/catalog/customer_catalog_store.dart';
import 'core/content/mobile_app_content_store.dart';
import 'core/auth/customer_account_sync.dart';
import 'core/auth/customer_auth_store.dart';
import 'core/chat/customer_chat_store.dart';
import 'core/addresses/customer_address_repository.dart';
import 'core/addresses/customer_address_store.dart';
import 'core/customer/customer_country.dart';
import 'core/customer/customer_personal_info_store.dart';
import 'core/customer/customer_profile_photo_store.dart';
import 'core/favorites/customer_favorites_store.dart';
import 'core/favorites/customer_favorites_repository.dart';
import 'core/gift_cards/customer_gift_card_store.dart';
import 'core/membership/customer_membership_store.dart';
import 'core/payments/customer_payment_method_store.dart';
import 'core/reviews/customer_review_store.dart';
import 'core/referrals/customer_referral_store.dart';
import 'core/rewards/customer_rewards_store.dart';
import 'core/rewards/customer_play_store.dart';
import 'core/rewards/customer_stamp_card_store.dart';
import 'core/settings/customer_preferences_repository.dart';
import 'core/settings/customer_settings_store.dart';
import 'core/vouchers/customer_voucher_store.dart';
import 'features/cart/cart_controller.dart';
import 'features/orders/orders_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  await CustomerAuthStore.initialize(config);
  await CustomerCatalogStore.initialize(CustomerAuthStore.instance.context);
  await MobileAppContentStore.initialize(CustomerAuthStore.instance.context);
  await CustomerCountryStore.initialize();
  await CustomerChatStore.initialize();
  await CustomerAddressStore.initialize(
    repository: CustomerAddressRepository(CustomerAuthStore.instance.context),
  );
  await CustomerPersonalInfoStore.initialize();
  await CustomerProfilePhotoStore.initialize();
  await CustomerFavoritesStore.initialize(
    repository: CustomerFavoritesRepository(CustomerAuthStore.instance.context),
  );
  await CustomerGiftCardStore.initialize();
  await CustomerMembershipStore.initialize(CustomerAuthStore.instance.context);
  await CustomerPaymentMethodStore.initialize();
  await CustomerRewardsStore.initialize(CustomerAuthStore.instance.context);
  await CustomerPlayStore.initialize();
  await CustomerStampCardStore.initialize(CustomerAuthStore.instance.context);
  await CustomerSettingsStore.initialize(
    repository:
        CustomerPreferencesRepository(CustomerAuthStore.instance.context),
  );
  await CustomerAccountSync.refreshAfterAuthentication();
  await CustomerVoucherStore.initialize();
  await CustomerReferralStore.initialize(CustomerAuthStore.instance.context);
  await CustomerReviewStore.initialize();
  await CustomerOrdersController.initialize();
  await CartController.initialize();
  runApp(GetinCoffeeApp(config: config));
}
