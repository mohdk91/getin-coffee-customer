import 'package:flutter/material.dart';

import '../../core/navigation/app_navigation_controller.dart';
import '../../core/products/product_type.dart';
import '../../core/theme/app_colors.dart';
import '../checkout/checkout_screen.dart';
import '../membership/membership_screen.dart';
import '../product/product_detail_screen.dart';
import '../rewards/reward_picker_sheet.dart';
import '../vouchers/voucher_picker_sheet.dart';
import 'cart_controller.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartController _cart = CartController.instance;
  late final TextEditingController _requestController;
  final TextEditingController _voucherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestController = TextEditingController(
      text: _cart.specialRequest,
    );
  }

  @override
  void dispose() {
    _requestController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  String _money(double value) {
    final currency = _cart.currency;
    final whole = value == value.roundToDouble();

    return whole
        ? '$currency ${value.toStringAsFixed(0)}'
        : '$currency ${value.toStringAsFixed(2)}';
  }

  Future<void> _editItem(CartItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          name: item.name,
          description: item.description,
          image: item.image,
          price: '${item.currency} ${item.basePrice.toStringAsFixed(0)}',
          branchName: item.branchName,
          serviceType: item.serviceType,
          editingItem: item,
        ),
      ),
    );
  }

  void _addRecommendation({
    required String name,
    required String description,
    required String image,
    required double price,
  }) {
    final branchName =
        _cart.cartBranchName ?? _cart.currentBranchName ?? 'Getin';

    final serviceType = _cart.cartServiceType ?? _cart.currentServiceType;

    _cart.addOrMerge(
      CartItem(
        name: name,
        description: description,
        image: image,
        branchName: branchName,
        serviceType: serviceType,
        currency: _cart.currency,
        basePrice: price,
        unitPrice: price,
        quantity: 1,
        strength: 'Regular',
        sweetness: 'Regular',
        addOns: const [],
        productType: GetinProductCatalog.definitionFor(name).type,
      ),
    );
  }

  void _submitVoucher() {
    final code = _voucherController.text.trim();

    if (code.isEmpty) {
      return;
    }

    final result = _cart.applyVoucherByCode(code);
    final message = switch (result) {
      VoucherApplyResult.success =>
        '${_cart.appliedVoucher?.code ?? code.toUpperCase()} applied · Save ${_money(_cart.voucherDiscount)}',
      VoucherApplyResult.emptyCart =>
        'Add items to your cart before applying a voucher.',
      VoucherApplyResult.notFound =>
        'Voucher code not found. Check the code and try again.',
      VoucherApplyResult.expired =>
        'This voucher has expired and cannot be applied.',
      VoucherApplyResult.used => 'This voucher has already been used.',
      VoucherApplyResult.minimumSpendNotMet =>
        'Minimum spend not reached for this voucher.',
    };

    if (result == VoucherApplyResult.success) {
      _voucherController.clear();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cart,
      builder: (context, _) {
        if (_cart.isEmpty) {
          return _EmptyCart(
            onBrowseMenu: () => Navigator.pop(context),
          );
        }

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
                        child: _CartHeader(
                          branchName: _cart.cartBranchName ?? 'Getin',
                          onBack: () => Navigator.pop(context),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          6,
                          16,
                          0,
                        ),
                        sliver: SliverList.separated(
                          itemCount: _cart.items.length,
                          separatorBuilder: (_, __) => const SizedBox(
                            height: 10,
                          ),
                          itemBuilder: (context, index) {
                            final item = _cart.items[index];

                            return _CartItemCard(
                              item: item,
                              onEdit: () => _editItem(item),
                              onDecrease: () => _cart.setQuantity(
                                item.signature,
                                item.quantity - 1,
                              ),
                              onIncrease: () => _cart.setQuantity(
                                item.signature,
                                item.quantity + 1,
                              ),
                              onRemove: () => _cart.remove(
                                item.signature,
                              ),
                            );
                          },
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            20,
                            16,
                            0,
                          ),
                          child: _Recommendations(
                            onAdd: _addRecommendation,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            18,
                            16,
                            0,
                          ),
                          child: _SpecialRequestCard(
                            controller: _requestController,
                            onChanged: _cart.setSpecialRequest,
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
                          child: _MembershipSavingsCard(
                            isMember: CartController.previewMember,
                            serviceType: _cart.cartServiceType ?? 'delivery',
                            deliveryFee: _cart.deliveryFee,
                            currency: _cart.currency,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MembershipScreen(),
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
                          child: _VoucherCard(
                            controller: _voucherController,
                            appliedCode: _cart.appliedVoucher?.code,
                            discount: _cart.voucherDiscount,
                            money: _money,
                            onSubmit: _submitVoucher,
                            onBrowse: () => showVoucherPickerSheet(
                              context,
                              cart: _cart,
                            ),
                            onRemove: _cart.appliedVoucher == null
                                ? null
                                : _cart.removeVoucher,
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
                          child: _RewardSavingsCard(
                            title: _cart.appliedRewardDefinition?.title,
                            discount: _cart.rewardDiscount,
                            money: _money,
                            onTap: () => showRewardPickerSheet(
                              context,
                              cart: _cart,
                            ),
                            onRemove: _cart.appliedReward == null
                                ? null
                                : _cart.removeReward,
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
                          child: _PaymentSummary(
                            subtotal: _cart.subtotal,
                            deliveryFee: _cart.deliveryFee,
                            serviceFee: _cart.serviceFee,
                            memberSaving: _cart.memberDeliverySaving,
                            voucherSaving: _cart.voucherDiscount,
                            voucherCode: _cart.appliedVoucher?.code,
                            rewardSaving: _cart.rewardDiscount,
                            rewardTitle: _cart.appliedRewardDefinition?.title,
                            total: _cart.totalBeforeTip(),
                            money: _money,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _CartBottomBar(
                  total: _money(
                    _cart.totalBeforeTip(),
                  ),
                  onAddItems: () {
                    AppNavigationController.instance.openMenu();
                    Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    );
                  },
                  onCheckout: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CheckoutScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartHeader extends StatelessWidget {
  final String branchName;
  final VoidCallback onBack;

  const _CartHeader({
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
                  'Cart',
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

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onEdit;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onEdit,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  String _money(double value) {
    final whole = value == value.roundToDouble();

    return whole
        ? '${item.currency} ${value.toStringAsFixed(0)}'
        : '${item.currency} ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 96,
              height: 96,
              color: AppColors.cream,
              child: Image.asset(
                item.image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 96),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.configurationSummary,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 9.5,
                      height: 1.25,
                    ),
                  ),
                  if (onEdit != null)
                    InkWell(
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 3,
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _money(
                            item.lineTotal,
                          ),
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _QuantityControl(
                        quantity: item.quantity,
                        onDecrease: onDecrease,
                        onIncrease: onIncrease,
                        onRemove: onRemove,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 33,
              minHeight: 33,
            ),
            onPressed: quantity == 1 ? onRemove : onDecrease,
            icon: Icon(
              quantity == 1
                  ? Icons.delete_outline_rounded
                  : Icons.remove_rounded,
              color: AppColors.green,
              size: 17,
            ),
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 33,
              minHeight: 33,
            ),
            onPressed: onIncrease,
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.green,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _Recommendations extends StatelessWidget {
  final void Function({
    required String name,
    required String description,
    required String image,
    required double price,
  }) onAdd;

  const _Recommendations({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        name: 'Butter Croissant',
        description: 'Classic buttery flaky croissant.',
        image: 'assets/images/products/butter_croissant.png',
        price: 45.0,
      ),
      (
        name: 'Blueberry Muffin',
        description: 'Soft muffin with blueberry pieces.',
        image: 'assets/images/products/blueberry_muffin.png',
        price: 60.0,
      ),
      (
        name: 'Turkey & Cheese',
        description: 'Turkey, cheese and fresh greens.',
        image: 'assets/images/products/turkey_cheese_sandwich.png',
        price: 95.0,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You might also like',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 11),
        SizedBox(
          height: MediaQuery.sizeOf(context).width < 380 ? 190 : 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final item = items[index];

              return Container(
                width: 126,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    15,
                  ),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        item.image,
                        width: double.infinity,
                        height: 82,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'EGP ${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => onAdd(
                            name: item.name,
                            description: item.description,
                            image: item.image,
                            price: item.price,
                          ),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: AppColors.beige,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SpecialRequestCard extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SpecialRequestCard({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Special request',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 2,
            minLines: 1,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Anything else we need to know?',
              hintStyle: const TextStyle(
                color: AppColors.muted,
                fontSize: 10.5,
              ),
              prefixIcon: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.green,
                size: 19,
              ),
              filled: true,
              fillColor: AppColors.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipSavingsCard extends StatelessWidget {
  final bool isMember;
  final String serviceType;
  final double deliveryFee;
  final String currency;
  final VoidCallback onTap;

  const _MembershipSavingsCard({
    required this.isMember,
    required this.serviceType,
    required this.deliveryFee,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final delivery = serviceType == 'delivery';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.beige,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMember
                  ? Icons.workspace_premium_rounded
                  : Icons.savings_outlined,
              color: AppColors.green,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMember
                      ? 'Getin Membership applied'
                      : 'Save with Getin Membership',
                  style: const TextStyle(
                    color: AppColors.beige,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isMember
                      ? delivery
                          ? 'Your qualifying delivery benefit is reflected below.'
                          : 'Your member benefits stay active on this order.'
                      : delivery
                          ? 'Member prices, 1.5× Stars and free delivery on qualifying orders.'
                          : 'Unlock member prices, 1.5× Stars and monthly perks.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9.3,
                    height: 1.25,
                  ),
                ),
                if (!isMember && delivery && deliveryFee > 0) ...[
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    'Potential delivery saving: $currency ${deliveryFee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 9.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.beige,
              side: const BorderSide(
                color: AppColors.beige,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              minimumSize: const Size(0, 38),
            ),
            child: Text(
              isMember ? 'View' : 'Join',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final TextEditingController controller;
  final String? appliedCode;
  final double discount;
  final String Function(double) money;
  final VoidCallback onSubmit;
  final VoidCallback onBrowse;
  final VoidCallback? onRemove;

  const _VoucherCard({
    required this.controller,
    required this.appliedCode,
    required this.discount,
    required this.money,
    required this.onSubmit,
    required this.onBrowse,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final applied = appliedCode != null;

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  color: AppColors.green,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Getin Vouchers',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      applied
                          ? '$appliedCode applied · Save ${money(discount)}'
                          : 'Choose an eligible voucher or enter a code',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onBrowse,
                child: Text(applied ? 'Change' : 'Apply'),
              ),
            ],
          ),
          if (applied && onRemove != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 17),
                label: const Text('Remove applied voucher'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Have a voucher code?',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onBrowse,
                child: const Text('View vouchers'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              hintText:
                  applied ? 'Enter another voucher code' : 'Enter voucher code',
              hintStyle: const TextStyle(
                color: AppColors.muted,
                fontSize: 10.5,
              ),
              prefixIcon: const Icon(
                Icons.local_offer_outlined,
                color: AppColors.green,
                size: 19,
              ),
              suffixIcon: TextButton(
                onPressed: onSubmit,
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              filled: true,
              fillColor: AppColors.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardSavingsCard extends StatelessWidget {
  final String? title;
  final double discount;
  final String Function(double) money;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _RewardSavingsCard({
    required this.title,
    required this.discount,
    required this.money,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final applied = title != null;

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: AppColors.green,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Getin Rewards',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      applied
                          ? '$title applied${discount > 0 ? ' · Save ${money(discount)}' : ''}'
                          : 'Apply an eligible redeemed reward',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onTap,
                child: Text(applied ? 'Change' : 'Apply'),
              ),
            ],
          ),
          if (applied && onRemove != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRemove,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('Remove reward'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double memberSaving;
  final double voucherSaving;
  final String? voucherCode;
  final double rewardSaving;
  final String? rewardTitle;
  final double total;
  final String Function(double) money;

  const _PaymentSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.memberSaving,
    required this.voucherSaving,
    required this.voucherCode,
    required this.rewardSaving,
    required this.rewardTitle,
    required this.total,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
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
          _SummaryRow(
            label: 'Subtotal',
            value: money(subtotal),
          ),
          if (deliveryFee > 0)
            _SummaryRow(
              label: 'Delivery fee',
              value: money(deliveryFee),
            ),
          _SummaryRow(
            label: 'Service fee',
            value: money(serviceFee),
          ),
          if (memberSaving > 0)
            _SummaryRow(
              label: 'Membership saving',
              value: '- ${money(memberSaving)}',
              highlight: true,
            ),
          if (voucherSaving > 0)
            _SummaryRow(
              label: voucherCode == null
                  ? 'Voucher saving'
                  : 'Voucher · $voucherCode',
              value: '- ${money(voucherSaving)}',
              highlight: true,
            ),
          if (rewardSaving > 0)
            _SummaryRow(
              label: rewardTitle == null
                  ? 'Reward saving'
                  : 'Reward · $rewardTitle',
              value: '- ${money(rewardSaving)}',
              highlight: true,
            ),
          const Divider(
            height: 22,
            color: AppColors.border,
          ),
          _SummaryRow(
            label: 'Total',
            value: money(total),
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final bool highlight;

  const _SummaryRow({
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

class _CartBottomBar extends StatelessWidget {
  final String total;
  final VoidCallback onAddItems;
  final VoidCallback onCheckout;

  const _CartBottomBar({
    required this.total,
    required this.onAddItems,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = width < 360 || textScale > 1.2;

    final addItemsButton = SizedBox(
      height: compact ? 46 : 50,
      child: OutlinedButton(
        onPressed: onAddItems,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green,
          side: const BorderSide(color: AppColors.green),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Add items',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );

    final checkoutButton = SizedBox(
      height: compact ? 52 : 50,
      child: FilledButton(
        onPressed: onCheckout,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.beige,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Checkout',
                style: TextStyle(fontWeight: FontWeight.w800),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  checkoutButton,
                  const SizedBox(height: 8),
                  addItemsButton,
                ],
              )
            : Row(
                children: [
                  Expanded(child: addItemsButton),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: checkoutButton),
                ],
              ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;

  const _WhiteCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onBrowseMenu;

  const _EmptyCart({
    required this.onBrowseMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: AppColors.beige,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.green,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Your cart is empty',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Add your Getin favorites and they will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onBrowseMenu,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.beige,
                  ),
                  child: const Text(
                    'Browse menu',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
