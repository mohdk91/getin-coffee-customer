import 'package:flutter/material.dart';

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
import '../theme/app_colors.dart';
import '../vouchers/customer_voucher_store.dart';

typedef CustomerBootstrapRunner = Future<void> Function(AppConfig config);

class CustomerAppBootstrapGate extends StatefulWidget {
  final AppConfig config;
  final Widget child;
  final CustomerBootstrapRunner? bootstrapper;

  const CustomerAppBootstrapGate({
    super.key,
    required this.config,
    required this.child,
    this.bootstrapper,
  });

  @override
  State<CustomerAppBootstrapGate> createState() =>
      _CustomerAppBootstrapGateState();
}

class _CustomerAppBootstrapGateState extends State<CustomerAppBootstrapGate> {
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() {
        _error = null;
        _ready = false;
      });
    }

    try {
      await (widget.bootstrapper ?? bootstrapCustomerApp)(widget.config);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;

    return Scaffold(
      backgroundColor: AppColors.green,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/getin_logo_mark.png',
                  width: 92,
                  height: 92,
                  errorBuilder: (_, __, ___) => const Text(
                    'GETIN',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_error == null) ...[
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.cream,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Preparing GETIN…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.cream,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Unable to start GETIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check the local API connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.cream),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    onPressed: _bootstrap,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> bootstrapCustomerApp(AppConfig config) async {
  // Auth initialization establishes the shared repository context and secure
  // token state. If this genuinely cannot initialize, expose a retry screen.
  await CustomerAuthStore.initialize(config);
  final context = CustomerAuthStore.instance.context;

  // Individual data refresh failures must not prevent the app from painting.
  // Repositories are initialized first; destination screens own later retries.
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

Future<void> _bestEffort(Future<void> Function() action) async {
  try {
    await action();
  } catch (_) {
    // Startup is intentionally fail-open for recoverable data refreshes.
    // Screens keep their repository wiring and can retry when opened.
  }
}
