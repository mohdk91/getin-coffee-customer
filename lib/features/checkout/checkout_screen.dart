import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/addresses/customer_address_store.dart';
import '../../core/gift_cards/customer_gift_card_store.dart';
import '../../core/membership/customer_membership_store.dart';
import '../../core/orders/checkout_order_draft.dart';
import '../../core/orders/checkout_order_service.dart';
import '../../core/payments/customer_payment_method_store.dart';
import '../../core/rewards/customer_rewards_store.dart';
import '../../core/rewards/customer_stamp_card_store.dart';
import '../../core/rewards/reward_earning_policy.dart';
import '../../core/theme/app_colors.dart';
import '../addresses/saved_addresses_screen.dart';
import '../cart/cart_controller.dart';
import '../membership/membership_screen.dart';
import '../rewards/reward_picker_sheet.dart';
import '../reviews/review_screens.dart';
import '../vouchers/voucher_picker_sheet.dart';
import '../orders/orders_screen.dart';
import '../orders/order_confirmation_screen.dart';
import '../payments/payment_methods_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartController _cart = CartController.instance;
  final CheckoutOrderService _orderService = DemoCheckoutOrderService.instance;

  static const String _deliveryEta = '20–30 min';
  static const String _pickupReadyTime = '10–15 min';

  double _tip = 0;
  String? _instruction;
  String _paymentTender = 'card';
  bool _placingOrder = false;
  bool _useGiftCardBalance = false;
  String? _orderError;

  String _formatMoney(String currency, double value) {
    final whole = value == value.roundToDouble();
    return whole
        ? '$currency ${value.toStringAsFixed(0)}'
        : '$currency ${value.toStringAsFixed(2)}';
  }

  String _money(double value) => _formatMoney(_cart.currency, value);

  double get _preGiftCardTotal => _cart.totalBeforeTip(
        tip: _tip,
      );

  double get _giftCardApplied {
    if (!_useGiftCardBalance) {
      return 0;
    }
    final balance = CustomerGiftCardStore.instance.balance;
    return balance < _preGiftCardTotal ? balance : _preGiftCardTotal;
  }

  double get _total => (_preGiftCardTotal - _giftCardApplied)
      .clamp(0.0, double.infinity)
      .toDouble();

  Future<void> _chooseDeliveryAddress() async {
    final selected = await showSavedAddressPicker(context);
    if (!mounted || selected == null) {
      return;
    }
    setState(() {});
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty || _placingOrder) {
      return;
    }

    if (!_cart.hasConsistentOrderContext) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your cart contains mixed branch/service items. Review the cart before checkout.',
          ),
        ),
      );
      return;
    }

    final delivery =
        (_cart.cartServiceType ?? _cart.currentServiceType) == 'delivery';
    final deliveryAddress = CustomerAddressStore.instance.checkoutAddress;

    if (delivery && deliveryAddress == null) {
      await _chooseDeliveryAddress();
      return;
    }

    if (_paymentTender == 'cash' && !CartController.previewCashAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cash is not available for this branch/country checkout policy.',
          ),
        ),
      );
      return;
    }

    final selectedCard = CustomerPaymentMethodStore.instance.checkoutMethod;
    if (_total > 0 && _paymentTender == 'card') {
      if (selectedCard == null || selectedCard.isExpired) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Choose an active saved card before placing this demo order.',
            ),
          ),
        );
        return;
      }
    }

    final branchName =
        _cart.cartBranchName ?? _cart.currentBranchName ?? 'Getin';
    final effectiveDeliveryInstruction = delivery
        ? (_instruction ?? deliveryAddress?.deliveryInstructions)
        : null;
    final fulfilmentEstimate = delivery ? _deliveryEta : _pickupReadyTime;

    final draft = CheckoutOrderDraft(
      clientRequestId: 'getin-demo-${DateTime.now().microsecondsSinceEpoch}',
      createdAt: DateTime.now(),
      branchId: _cart.cartBranchId ?? _cart.currentBranchId,
      branchName: branchName,
      serviceType: delivery ? 'delivery' : 'pickup',
      currency: _cart.currency,
      lines: _cart.items
          .map(
            (item) => CheckoutOrderLine(
              productId: item.productId,
              variantId: item.variantId,
              optionValueIds: List<int>.unmodifiable(item.optionValueIds),
              name: item.name,
              productType: item.productType.name,
              description: item.description,
              image: item.image,
              basePrice: item.basePrice,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              size: item.size,
              temperature: item.temperature,
              milk: item.milk,
              strength: item.strength,
              sweetness: item.sweetness,
              addOns: List<String>.unmodifiable(item.addOns),
              variant: item.variant,
              warming: item.warming,
              sauce: item.sauce,
              color: item.color,
            ),
          )
          .toList(growable: false),
      itemCount: _cart.itemCount,
      specialRequest: _cart.specialRequest,
      deliveryAddress: delivery && deliveryAddress != null
          ? CheckoutDeliveryAddress(
              id: deliveryAddress.id,
              label: deliveryAddress.label,
              area: deliveryAddress.area,
              city: deliveryAddress.city,
              building: deliveryAddress.building,
              floor: deliveryAddress.floor,
              apartment: deliveryAddress.apartment,
              latitude: deliveryAddress.latitude,
              longitude: deliveryAddress.longitude,
            )
          : null,
      deliveryInstruction: effectiveDeliveryInstruction,
      fulfilmentEstimate: fulfilmentEstimate,
      subtotal: _cart.subtotal,
      deliveryFee: _cart.deliveryFee,
      serviceFee: _cart.serviceFee,
      tip: delivery ? _tip : 0,
      membershipSaving: _cart.memberDeliverySaving,
      rewardSaving: _cart.rewardDiscount,
      rewardRedemptionId: _cart.appliedReward?.id,
      voucherSaving: _cart.voucherDiscount,
      voucherCode: _cart.appliedVoucher?.code,
      giftCardApplied: _giftCardApplied,
      paymentTender: _total <= 0 ? 'gift_card_balance' : _paymentTender,
      paymentMethodId:
          _total > 0 && _paymentTender == 'card' ? selectedCard?.id : null,
      paymentTokenReference: _total > 0 && _paymentTender == 'card'
          ? selectedCard?.providerTokenRef
          : null,
      total: _total,
    );

    final items = _cart.items;
    final images =
        items.map((item) => item.image).take(3).toList(growable: false);
    final reviewProducts = items
        .map(
          (item) => ReviewableProduct(
            name: item.name,
            description: item.description,
            image: item.image,
            price: _formatMoney(item.currency, item.unitPrice),
          ),
        )
        .toList(growable: false);

    setState(() {
      _placingOrder = true;
      _orderError = null;
    });

    // This is the single order-creation boundary. In production, replace the
    // demo service with a Laravel implementation that creates the order and
    // confirms/authorizes payment. Until this returns success, the cart,
    // reward, voucher and gift-card balance remain untouched.
    CheckoutOrderResult result;
    try {
      result = await _orderService
          .createOrder(draft)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      if (!mounted) return;
      const message =
          'The order service took too long to respond. Check your connection and try again. Your cart is unchanged.';
      setState(() {
        _placingOrder = false;
        _orderError = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(message)),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      const message =
          'We could not create the order right now. Try again. Your cart, reward, voucher and Gift Card Balance are unchanged.';
      setState(() {
        _placingOrder = false;
        _orderError = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(message)),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    if (!result.success || result.orderId == null) {
      setState(() {
        _placingOrder = false;
        _orderError = result.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    // Award demo loyalty only AFTER order creation succeeds. Production
    // Laravel should be the source of truth for eligible spend and reward rules.
    final memberActive = CustomerMembershipStore.instance.isActive;
    final earnedStars = RewardEarningPolicy.starsForAmount(
      draft.subtotal,
      isMember: memberActive,
    );
    CustomerRewardsStore.instance.addOrderEarnings(
      stars: earnedStars,
      orderId: result.orderId!,
      memberMultiplierApplied: memberActive,
    );

    final eligibleDrinkQuantity = items
        .where((item) => RewardEarningPolicy.earnsStamp(item.productType))
        .fold<int>(0, (sum, item) => sum + item.quantity);
    final stampResult = CustomerStampCardStore.instance.addEligibleDrinks(
      eligibleDrinkQuantity,
    );
    for (var index = 0; index < stampResult.cardsCompleted; index++) {
      CustomerRewardsStore.instance.grantFreeDrinkReward(
        source: 'stamp-card',
      );
    }

    // Consume local benefits/store credit only AFTER order creation succeeds.
    if (_giftCardApplied > 0) {
      await CustomerGiftCardStore.instance.spendBalance(_giftCardApplied);
    }

    _cart.completeDemoOrder();

    if (!mounted) {
      return;
    }

    final order = GetinOrder(
      id: result.orderId!,
      placedAt: draft.createdAt,
      branchName: branchName,
      fulfillment: delivery ? 'Delivery' : 'Pickup',
      status: GetinOrderStatus.confirmed,
      itemCount: draft.itemCount,
      total: _formatMoney(draft.currency, draft.total),
      itemImages: images,
      reviewProducts: reviewProducts,
      eta: fulfilmentEstimate,
      deliveryAddress: delivery
          ? '${deliveryAddress!.labelUpper} · ${deliveryAddress.title}'
          : null,
      deliveryLatitude: delivery ? deliveryAddress!.latitude : null,
      deliveryLongitude: delivery ? deliveryAddress!.longitude : null,
      deliveryCode: delivery ? '4728' : null,
    );

    CustomerOrdersController.instance.addCreatedOrder(order);

    setState(() => _placingOrder = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          order: order,
          delivery: delivery,
          earnedStars: earnedStars,
          earnedStamps: stampResult.stampsAdded,
          currentStamps: stampResult.currentStamps,
          freeDrinksUnlocked: stampResult.cardsCompleted,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.green,
          elevation: 0,
          title: const Text('Checkout'),
        ),
        body: const Center(
          child: Text(
            'Your cart is empty.',
            style: TextStyle(
              color: AppColors.green,
            ),
          ),
        ),
      );
    }

    final delivery =
        (_cart.cartServiceType ?? _cart.currentServiceType) == 'delivery';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _CheckoutHeader(
                      branchName: _cart.cartBranchName ?? 'Getin',
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        0,
                      ),
                      child: delivery
                          ? _DeliveryLocationCard(
                              address:
                                  CustomerAddressStore.instance.checkoutAddress,
                              onChange: _chooseDeliveryAddress,
                            )
                          : _PickupLocationCard(
                              branchName: _cart.cartBranchName ?? 'Getin',
                            ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        0,
                      ),
                      child: _FulfilmentCard(
                        delivery: delivery,
                        estimate: delivery ? _deliveryEta : _pickupReadyTime,
                      ),
                    ),
                  ),
                  if (delivery)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          0,
                        ),
                        child: _TipCard(
                          selectedTip: _tip,
                          currency: _cart.currency,
                          onSelected: (value) {
                            setState(() {
                              _tip = value;
                            });
                          },
                        ),
                      ),
                    ),
                  if (delivery)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          0,
                        ),
                        child: _DeliveryInstructionsCard(
                          selected: _instruction,
                          onSelected: (value) {
                            setState(() {
                              _instruction =
                                  _instruction == value ? null : value;
                            });
                          },
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        0,
                      ),
                      child: _CheckoutMembershipCard(
                        isMember: CartController.previewMember,
                        delivery: delivery,
                        deliveryFee: _cart.deliveryFee,
                        currency: _cart.currency,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MembershipScreen(
                                showBackButton: true,
                              ),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        0,
                      ),
                      child: _CheckoutVoucherCard(
                        code: _cart.appliedVoucher?.code,
                        discount: _cart.voucherDiscount,
                        money: _money,
                        onTap: () async {
                          await showVoucherPickerSheet(
                            context,
                            cart: _cart,
                          );
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        onRemove: _cart.appliedVoucher == null
                            ? null
                            : () {
                                _cart.removeVoucher();
                                setState(() {});
                              },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        0,
                      ),
                      child: _CheckoutRewardCard(
                        title: _cart.appliedRewardDefinition?.title,
                        discount: _cart.rewardDiscount,
                        money: _money,
                        onTap: () async {
                          await showRewardPickerSheet(
                            context,
                            cart: _cart,
                          );
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        onRemove: _cart.appliedReward == null
                            ? null
                            : () {
                                _cart.removeReward();
                                setState(() {});
                              },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        0,
                      ),
                      child: _GiftCardBalanceCheckoutCard(
                        balance: CustomerGiftCardStore.instance.balance,
                        applied: _giftCardApplied,
                        enabled: _useGiftCardBalance,
                        money: _money,
                        onChanged: CustomerGiftCardStore.instance.balance <= 0
                            ? null
                            : (value) {
                                setState(() {
                                  _useGiftCardBalance = value;
                                });
                              },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        0,
                      ),
                      child: _PaymentMethodCard(
                        selectedTender: _paymentTender,
                        selectedCard:
                            CustomerPaymentMethodStore.instance.checkoutMethod,
                        showCash: CartController.previewCashAllowed,
                        onSelectCard: () async {
                          final selected =
                              await showSavedPaymentMethodPicker(context);
                          if (!mounted || selected == null) {
                            return;
                          }
                          setState(() {
                            _paymentTender = 'card';
                          });
                        },
                        onAddCard: () async {
                          final added = await showAddDemoCardSheet(context);
                          if (!mounted || added == null) {
                            return;
                          }
                          await CustomerPaymentMethodStore.instance
                              .selectForCheckout(added.id);
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _paymentTender = 'card';
                          });
                        },
                        onSelectCash: () {
                          setState(() {
                            _paymentTender = 'cash';
                          });
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        18,
                        16,
                        28,
                      ),
                      child: _CheckoutSummary(
                        subtotal: _cart.subtotal,
                        deliveryFee: _cart.deliveryFee,
                        serviceFee: _cart.serviceFee,
                        tip: _tip,
                        memberSaving: _cart.memberDeliverySaving,
                        voucherSaving: _cart.voucherDiscount,
                        voucherCode: _cart.appliedVoucher?.code,
                        rewardSaving: _cart.rewardDiscount,
                        rewardTitle: _cart.appliedRewardDefinition?.title,
                        giftCardSaving: _giftCardApplied,
                        total: _total,
                        money: _money,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _CheckoutBottomBar(
              isMember: CartController.previewMember,
              delivery: delivery,
              deliveryFee: _cart.deliveryFee,
              currency: _cart.currency,
              total: _money(_total),
              onMembership: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MembershipScreen(
                      showBackButton: true,
                    ),
                  ),
                );
                if (mounted) setState(() {});
              },
              placingOrder: _placingOrder,
              errorMessage: _orderError,
              onPlaceOrder: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  final String branchName;
  final VoidCallback onBack;

  const _CheckoutHeader({
    required this.branchName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        16,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.green,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Checkout',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  branchName,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryLocationCard extends StatelessWidget {
  final CustomerAddress? address;
  final VoidCallback onChange;

  const _DeliveryLocationCard({
    required this.address,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final selected = address;
    final hasAddress = selected != null;

    return _CheckoutCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (selected != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 132,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      selected.latitude,
                      selected.longitude,
                    ),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.getin.coffee',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            selected.latitude,
                            selected.longitude,
                          ),
                          width: 48,
                          height: 48,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.beige,
                              size: 27,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 112,
              decoration: const BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_location_alt_outlined,
                  color: AppColors.green,
                  size: 38,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.green,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected != null
                            ? '${selected.labelUpper} · ${selected.title}'
                            : 'Choose delivery address',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        selected != null
                            ? selected.details
                            : 'Add or choose one of your saved addresses.',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 9.5,
                        ),
                      ),
                      if (selected != null &&
                          selected.deliveryInstructions.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          selected.deliveryInstructions,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onChange,
                  child: Text(
                    hasAddress ? 'Change' : 'Choose',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupLocationCard extends StatelessWidget {
  final String branchName;

  const _PickupLocationCard({
    required this.branchName,
  });

  @override
  Widget build(BuildContext context) {
    return _CheckoutCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.beige,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pickup branch',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 8.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  branchName,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Change',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FulfilmentCard extends StatelessWidget {
  final bool delivery;
  final String estimate;

  const _FulfilmentCard({
    required this.delivery,
    required this.estimate,
  });

  @override
  Widget build(BuildContext context) {
    return _CheckoutCard(
      child: Row(
        children: [
          Icon(
            delivery
                ? Icons.delivery_dining_rounded
                : Icons.shopping_bag_rounded,
            color: AppColors.green,
            size: 24,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery ? 'Delivery' : 'Pickup',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  delivery
                      ? 'Estimated arrival: $estimate'
                      : 'Estimated ready time: $estimate',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.schedule_rounded,
            color: AppColors.green,
            size: 19,
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final double selectedTip;
  final String currency;
  final ValueChanged<double> onSelected;

  const _TipCard({
    required this.selectedTip,
    required this.currency,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const values = [
      0.0,
      10.0,
      20.0,
      30.0,
    ];

    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Say thanks with a tip',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Your driver keeps 100% of the tip.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map(
              (value) {
                final selected = selectedTip == value;

                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => onSelected(value),
                  selectedColor: AppColors.green,
                  backgroundColor: AppColors.cream,
                  label: Text(
                    value == 0
                        ? 'No tip'
                        : '$currency ${value.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: selected ? AppColors.beige : AppColors.green,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.green : AppColors.border,
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }
}

class _DeliveryInstructionsCard extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const _DeliveryInstructionsCard({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const options = <(String, IconData)>[
      (
        'Call on arrival',
        Icons.phone_outlined,
      ),
      (
        'Do not ring',
        Icons.notifications_off_outlined,
      ),
      (
        'Leave at reception',
        Icons.room_service_outlined,
      ),
      (
        'Ring doorbell',
        Icons.notifications_active_outlined,
      ),
    ];

    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery instructions',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = options[index];
                final active = selected == option.$1;

                return InkWell(
                  onTap: () => onSelected(
                    option.$1,
                  ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.beige.withOpacity(
                              0.55,
                            )
                          : AppColors.cream,
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                      border: Border.all(
                        color: active ? AppColors.green : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          option.$2,
                          color: AppColors.green,
                          size: 21,
                        ),
                        const Spacer(),
                        Text(
                          option.$1,
                          maxLines: 2,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 9.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutMembershipCard extends StatelessWidget {
  final bool isMember;
  final bool delivery;
  final double deliveryFee;
  final String currency;
  final VoidCallback onTap;

  const _CheckoutMembershipCard({
    required this.isMember,
    required this.delivery,
    required this.deliveryFee,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMember ? const Color(0xFFEAF1E9) : AppColors.green,
        borderRadius: BorderRadius.circular(18),
        border: isMember
            ? Border.all(
                color: AppColors.border,
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: isMember ? AppColors.green : AppColors.gold,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMember
                      ? 'Membership benefit applied'
                      : 'Save more before you order',
                  style: TextStyle(
                    color: isMember ? AppColors.green : AppColors.beige,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isMember
                      ? delivery
                          ? 'Free delivery applied for this preview order.'
                          : 'Your membership is active on this pickup.'
                      : delivery
                          ? 'Join Getin Membership for free delivery on qualifying orders, member prices and 1.5× Stars.'
                          : 'Join for member prices, 1.5× Stars and monthly perks.',
                  style: TextStyle(
                    color: isMember ? AppColors.muted : Colors.white70,
                    fontSize: 9.2,
                    height: 1.25,
                  ),
                ),
                if (!isMember && delivery && deliveryFee > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Potential saving now: $currency ${deliveryFee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 9.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onTap,
            child: Text(
              isMember ? 'View' : 'Join',
              style: TextStyle(
                color: isMember ? AppColors.green : AppColors.beige,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutVoucherCard extends StatelessWidget {
  final String? code;
  final double discount;
  final String Function(double) money;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _CheckoutVoucherCard({
    required this.code,
    required this.discount,
    required this.money,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final applied = code != null;

    return _CheckoutCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.green,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voucher',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  applied
                      ? '$code applied${discount > 0 ? ' · -${money(discount)}' : ''}'
                      : 'Choose an eligible voucher',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          if (applied && onRemove != null)
            IconButton(
              tooltip: 'Remove voucher',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
              color: AppColors.muted,
            ),
          TextButton(
            onPressed: onTap,
            child: Text(applied ? 'Change' : 'Apply'),
          ),
        ],
      ),
    );
  }
}

class _CheckoutRewardCard extends StatelessWidget {
  final String? title;
  final double discount;
  final String Function(double) money;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _CheckoutRewardCard({
    required this.title,
    required this.discount,
    required this.money,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final applied = title != null;

    return _CheckoutCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppColors.green,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Getin Reward',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  applied
                      ? '$title${discount > 0 ? ' · -${money(discount)}' : ''}'
                      : 'Apply an eligible redeemed reward',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          if (applied && onRemove != null)
            IconButton(
              tooltip: 'Remove reward',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
              color: AppColors.muted,
            ),
          TextButton(
            onPressed: onTap,
            child: Text(applied ? 'Change' : 'Apply'),
          ),
        ],
      ),
    );
  }
}

class _GiftCardBalanceCheckoutCard extends StatelessWidget {
  final double balance;
  final double applied;
  final bool enabled;
  final String Function(double) money;
  final ValueChanged<bool>? onChanged;

  const _GiftCardBalanceCheckoutCard({
    required this.balance,
    required this.applied,
    required this.enabled,
    required this.money,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _CheckoutCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gift Card Balance',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  balance <= 0
                      ? 'No gift-card balance available'
                      : enabled && applied > 0
                          ? '${money(applied)} applied · ${money(balance)} available'
                          : '${money(balance)} available',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Separate from saved payment cards and cash.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled && balance > 0,
            onChanged: onChanged,
            activeColor: AppColors.green,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String selectedTender;
  final CustomerPaymentMethod? selectedCard;
  final bool showCash;
  final VoidCallback onSelectCard;
  final VoidCallback onAddCard;
  final VoidCallback onSelectCash;

  const _PaymentMethodCard({
    required this.selectedTender,
    required this.selectedCard,
    required this.showCash,
    required this.onSelectCard,
    required this.onAddCard,
    required this.onSelectCash,
  });

  @override
  Widget build(BuildContext context) {
    final card = selectedCard;
    final cardTitle = card?.maskedLabel ?? 'Choose a saved card';
    final cardSubtitle = card == null
        ? 'Add or select a tokenized demo card'
        : '${card.isDefault ? 'Default · ' : ''}Expires ${card.expiryLabel}';

    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pay with',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _PaymentOption(
            icon: Icons.credit_card_rounded,
            title: cardTitle,
            subtitle: cardSubtitle,
            selected: selectedTender == 'card',
            onTap: onSelectCard,
          ),
          const Divider(
            height: 1,
            color: AppColors.border,
          ),
          _PaymentOption(
            icon: Icons.add_circle_outline_rounded,
            title: 'Add new card',
            subtitle: 'Secure provider-style demo setup',
            selected: false,
            onTap: onAddCard,
            showRadio: false,
          ),
          if (showCash) ...[
            const Divider(
              height: 1,
              color: AppColors.border,
            ),
            _PaymentOption(
              icon: Icons.payments_outlined,
              title: 'Cash',
              subtitle: 'Shown only when allowed by branch policy',
              selected: selectedTender == 'cash',
              onTap: onSelectCash,
            ),
          ],
          const Divider(
            height: 1,
            color: AppColors.border,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: AppColors.green,
                  size: 17,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Demo stores only masked card metadata and a simulated provider token reference. Full card details are never stored.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 8.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool showRadio;

  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.showRadio = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 11,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.green,
              size: 22,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            ),
            if (showRadio)
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: AppColors.green,
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.green,
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutSummary extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double tip;
  final double memberSaving;
  final double voucherSaving;
  final String? voucherCode;
  final double rewardSaving;
  final String? rewardTitle;
  final double giftCardSaving;
  final double total;
  final String Function(double) money;

  const _CheckoutSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.tip,
    required this.memberSaving,
    required this.voucherSaving,
    required this.voucherCode,
    required this.rewardSaving,
    required this.rewardTitle,
    required this.giftCardSaving,
    required this.total,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment summary',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          _CheckoutSummaryRow(
            label: 'Subtotal',
            value: money(subtotal),
          ),
          if (deliveryFee > 0)
            _CheckoutSummaryRow(
              label: 'Delivery fee',
              value: money(deliveryFee),
            ),
          _CheckoutSummaryRow(
            label: 'Service fee',
            value: money(serviceFee),
          ),
          if (tip > 0)
            _CheckoutSummaryRow(
              label: 'Driver tip',
              value: money(tip),
            ),
          if (memberSaving > 0)
            _CheckoutSummaryRow(
              label: 'Membership saving',
              value: '- ${money(memberSaving)}',
              highlight: true,
            ),
          if (voucherSaving > 0)
            _CheckoutSummaryRow(
              label: voucherCode == null
                  ? 'Voucher saving'
                  : 'Voucher · $voucherCode',
              value: '- ${money(voucherSaving)}',
              highlight: true,
            ),
          if (rewardSaving > 0)
            _CheckoutSummaryRow(
              label: rewardTitle == null
                  ? 'Reward saving'
                  : 'Reward · $rewardTitle',
              value: '- ${money(rewardSaving)}',
              highlight: true,
            ),
          if (giftCardSaving > 0)
            _CheckoutSummaryRow(
              label: 'Gift Card Balance',
              value: '- ${money(giftCardSaving)}',
              highlight: true,
            ),
          const Divider(
            height: 22,
            color: AppColors.border,
          ),
          _CheckoutSummaryRow(
            label: 'Total amount',
            value: money(total),
            strong: true,
          ),
          const SizedBox(height: 14),
          const Text(
            'By placing the order you agree to Getin Coffee’s checkout terms and the policies applicable to your selected branch.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 8.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final bool highlight;

  const _CheckoutSummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: highlight ? AppColors.gold : AppColors.green,
      fontSize: strong ? 13 : 10.5,
      fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: style,
            ),
          ),
          Text(
            value,
            style: style,
          ),
        ],
      ),
    );
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  final bool isMember;
  final bool delivery;
  final double deliveryFee;
  final String currency;
  final String total;
  final VoidCallback onMembership;
  final VoidCallback onPlaceOrder;
  final bool placingOrder;
  final String? errorMessage;

  const _CheckoutBottomBar({
    required this.isMember,
    required this.delivery,
    required this.deliveryFee,
    required this.currency,
    required this.total,
    required this.onMembership,
    required this.onPlaceOrder,
    required this.placingOrder,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = width < 360 || textScale > 1.2;
    final savingText = isMember
        ? 'Benefit applied'
        : delivery && deliveryFee > 0
            ? 'Save $currency ${deliveryFee.toStringAsFixed(2)}'
            : '1.5× Stars + perks';

    final membershipCard = InkWell(
      onTap: onMembership,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 52 : 62),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: isMember ? const Color(0xFFEAF1E9) : AppColors.cream,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border),
        ),
        child: compact
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      isMember ? 'Membership' : 'Join Membership',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      savingText,
                      maxLines: 2,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: isMember ? AppColors.green : AppColors.gold,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isMember ? 'Membership' : 'Join Membership',
                    softWrap: true,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    savingText,
                    softWrap: true,
                    style: TextStyle(
                      color: isMember ? AppColors.green : AppColors.gold,
                      fontSize: 8.3,
                      fontWeight: FontWeight.w700,
                      height: 1.12,
                    ),
                  ),
                ],
              ),
      ),
    );

    final orderButton = SizedBox(
      height: 62,
      child: FilledButton(
        onPressed: placingOrder ? null : onPlaceOrder,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.beige,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                placingOrder ? 'Placing order...' : 'Place order',
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  total,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorMessage != null && errorMessage!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6B8A2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: Color(0xFF9A4E2F),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFF7A3E28),
                          fontSize: 9.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (compact)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  orderButton,
                  const SizedBox(height: 7),
                  membershipCard,
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 5, child: membershipCard),
                  const SizedBox(width: 9),
                  Expanded(flex: 10, child: orderButton),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CheckoutCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
