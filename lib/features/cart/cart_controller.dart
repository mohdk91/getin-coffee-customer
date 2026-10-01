import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/membership/customer_membership_store.dart';
import '../../core/products/product_type.dart';
import '../../core/rewards/customer_rewards_store.dart';
import '../../core/vouchers/customer_voucher_store.dart';

class CartItem {
  final int? branchId;
  final int? productId;
  final int? variantId;
  final List<int> optionValueIds;
  final String name;
  final String description;
  final String image;
  final String branchName;
  final String serviceType;
  final String currency;
  final double basePrice;
  final double unitPrice;
  final int quantity;
  final String? size;
  final String? temperature;
  final String? milk;
  final String strength;
  final String sweetness;
  final List<String> addOns;
  final ProductType productType;
  final String? variant;
  final String? warming;
  final String? sauce;
  final String? color;

  const CartItem({
    this.branchId,
    this.productId,
    this.variantId,
    this.optionValueIds = const <int>[],
    required this.name,
    required this.description,
    required this.image,
    required this.branchName,
    required this.serviceType,
    required this.currency,
    required this.basePrice,
    required this.unitPrice,
    required this.quantity,
    required this.strength,
    required this.sweetness,
    required this.addOns,
    this.productType = ProductType.drink,
    this.variant,
    this.warming,
    this.sauce,
    this.color,
    this.size,
    this.temperature,
    this.milk,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final typeName = json['productType'] as String? ?? ProductType.drink.name;
    final productType = ProductType.values.firstWhere(
      (type) => type.name == typeName,
      orElse: () => ProductType.drink,
    );
    final rawAddOns = json['addOns'];

    return CartItem(
      branchId: (json['branchId'] as num?)?.toInt(),
      productId: (json['productId'] as num?)?.toInt(),
      variantId: (json['variantId'] as num?)?.toInt(),
      optionValueIds: (json['optionValueIds'] as List? ?? const <dynamic>[])
          .whereType<num>()
          .map((value) => value.toInt())
          .toList(growable: false),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      image: json['image'] as String? ?? '',
      branchName: json['branchName'] as String? ?? '',
      serviceType: json['serviceType'] as String? ?? 'delivery',
      currency: json['currency'] as String? ?? 'EGP',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      strength: json['strength'] as String? ?? 'Regular',
      sweetness: json['sweetness'] as String? ?? 'Regular',
      addOns: rawAddOns is List
          ? rawAddOns.whereType<String>().toList(growable: false)
          : const <String>[],
      productType: productType,
      variant: json['variant'] as String?,
      warming: json['warming'] as String?,
      sauce: json['sauce'] as String?,
      color: json['color'] as String?,
      size: json['size'] as String?,
      temperature: json['temperature'] as String?,
      milk: json['milk'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'branchId': branchId,
        'productId': productId,
        'variantId': variantId,
        'optionValueIds': optionValueIds,
        'name': name,
        'description': description,
        'image': image,
        'branchName': branchName,
        'serviceType': serviceType,
        'currency': currency,
        'basePrice': basePrice,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'strength': strength,
        'sweetness': sweetness,
        'addOns': addOns,
        'productType': productType.name,
        'variant': variant,
        'warming': warming,
        'sauce': sauce,
        'color': color,
        'size': size,
        'temperature': temperature,
        'milk': milk,
      };

  String get signature {
    final sortedAddOns = [...addOns]..sort();
    return [
      branchId?.toString() ?? '',
      productId?.toString() ?? '',
      variantId?.toString() ?? '',
      ([...optionValueIds]..sort()).join(','),
      branchName,
      serviceType,
      currency,
      name,
      productType.name,
      size ?? '',
      temperature ?? '',
      milk ?? '',
      strength,
      sweetness,
      variant ?? '',
      warming ?? '',
      sauce ?? '',
      color ?? '',
      sortedAddOns.join(','),
    ].join('|');
  }

  bool get hasServerIdentity => branchId != null && productId != null;

  double get lineTotal => unitPrice * quantity;

  String get configurationSummary {
    final values = <String>[];

    switch (productType) {
      case ProductType.drink:
        values.addAll([
          if (size != null) size!,
          if (temperature != null) temperature!,
          if (milk != null) milk!,
          if (strength != 'Regular') strength,
          if (sweetness != 'Regular') sweetness,
        ]);
        break;
      case ProductType.refreshment:
        values.addAll([
          if (size != null) size!,
          if (variant != null) variant!,
          if (sweetness != 'Regular') sweetness,
        ]);
        break;
      case ProductType.food:
      case ProductType.bakery:
        values.addAll([
          if (warming != null) warming!,
          if (variant != null && variant != 'Classic') variant!,
          if (sauce != null && sauce != 'No Sauce') sauce!,
        ]);
        break;
      case ProductType.merchandise:
        values.addAll([
          if (variant != null) variant!,
          if (size != null) size!,
          if (color != null) color!,
        ]);
        break;
    }

    values.addAll(addOns);
    return values.isEmpty ? 'Standard' : values.join(' · ');
  }

  CartItem copyWith({
    int? branchId,
    int? productId,
    int? variantId,
    List<int>? optionValueIds,
    int? quantity,
    double? unitPrice,
    String? size,
    String? temperature,
    String? milk,
    String? strength,
    String? sweetness,
    List<String>? addOns,
    ProductType? productType,
    String? variant,
    String? warming,
    String? sauce,
    String? color,
  }) {
    return CartItem(
      branchId: branchId ?? this.branchId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      optionValueIds: optionValueIds ?? this.optionValueIds,
      name: name,
      description: description,
      image: image,
      branchName: branchName,
      serviceType: serviceType,
      currency: currency,
      basePrice: basePrice,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      temperature: temperature ?? this.temperature,
      milk: milk ?? this.milk,
      strength: strength ?? this.strength,
      sweetness: sweetness ?? this.sweetness,
      addOns: addOns ?? this.addOns,
      productType: productType ?? this.productType,
      variant: variant ?? this.variant,
      warming: warming ?? this.warming,
      sauce: sauce ?? this.sauce,
      color: color ?? this.color,
    );
  }
}

enum VoucherApplyResult {
  success,
  emptyCart,
  notFound,
  expired,
  used,
  minimumSpendNotMet,
}

class CartController extends ChangeNotifier {
  CartController._();

  static final CartController instance = CartController._();
  static const String _storageKey = 'getin_demo_cart_v2';

  SharedPreferences? _preferences;
  bool _initialized = false;

  static bool get previewMember => CustomerMembershipStore.instance.isActive;

  static const bool previewCashAllowed = bool.fromEnvironment(
    'GETIN_PREVIEW_CASH_ALLOWED',
    defaultValue: true,
  );

  final List<CartItem> _items = <CartItem>[];

  int? _currentBranchId;
  String? _currentBranchName;
  String _currentServiceType = 'delivery';
  double? _userLatitude;
  double? _userLongitude;
  String _specialRequest = '';
  String? _appliedRewardId;
  String? _appliedVoucherId;

  static Future<void> initialize() => instance._initialize();

  Future<void> _initialize() async {
    if (_initialized) return;

    _preferences = await SharedPreferences.getInstance();
    _initialized = true;
    await _restore();
  }

  Future<void> _restore() async {
    final raw = _preferences?.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final map = Map<String, dynamic>.from(decoded);
      final rawItems = map['items'];
      final restored = rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((entry) =>
                  CartItem.fromJson(Map<String, dynamic>.from(entry)))
              .where((item) =>
                  item.name.isNotEmpty &&
                  item.branchName.isNotEmpty &&
                  item.quantity > 0)
              .toList(growable: false)
          : <CartItem>[];

      _items
        ..clear()
        ..addAll(restored);
      _currentBranchId = (map['currentBranchId'] as num?)?.toInt();
      _currentBranchName = map['currentBranchName'] as String?;
      _currentServiceType = map['currentServiceType'] as String? ?? 'delivery';
      _userLatitude = (map['userLatitude'] as num?)?.toDouble();
      _userLongitude = (map['userLongitude'] as num?)?.toDouble();
      _specialRequest = map['specialRequest'] as String? ?? '';
      _appliedRewardId = map['appliedRewardId'] as String?;
      _appliedVoucherId = map['appliedVoucherId'] as String?;

      if (!hasConsistentOrderContext) {
        _items.clear();
        _specialRequest = '';
        _appliedRewardId = null;
        _appliedVoucherId = null;
      }

      if (_items.isEmpty) {
        _cleanupOrderMetadataIfEmpty();
      } else {
        final reward = appliedReward;
        if (reward != null && isRewardApplicable(reward)) {
          CustomerRewardsStore.instance.markApplied(reward.id);
        } else {
          _appliedRewardId = null;
        }

        final voucher = appliedVoucher;
        if (voucher != null && isVoucherApplicable(voucher)) {
          CustomerVoucherStore.instance.markApplied(voucher.id);
        } else {
          _appliedVoucherId = null;
        }
      }

      notifyListeners();
      unawaited(_persist());
    } catch (_) {
      _items.clear();
      _specialRequest = '';
      _appliedRewardId = null;
      _appliedVoucherId = null;
      await _preferences?.remove(_storageKey);
    }
  }

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  int get itemCount {
    return _items.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  int? get cartBranchId {
    return _items.isEmpty ? null : _items.first.branchId;
  }

  String? get cartBranchName {
    return _items.isEmpty ? null : _items.first.branchName;
  }

  String? get cartServiceType {
    return _items.isEmpty ? null : _items.first.serviceType;
  }

  String get currency {
    return _items.isEmpty ? 'EGP' : _items.first.currency;
  }

  int? get currentBranchId => _currentBranchId;
  String? get currentBranchName => _currentBranchName;
  String get currentServiceType => _currentServiceType;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  String get specialRequest => _specialRequest;

  RedeemedReward? get appliedReward {
    final id = _appliedRewardId;
    if (id == null) {
      return null;
    }
    return CustomerRewardsStore.instance.redeemedById(id);
  }

  RewardDefinition? get appliedRewardDefinition {
    final reward = appliedReward;
    if (reward == null) {
      return null;
    }
    return CustomerRewardsStore.instance.definitionFor(reward.definitionId);
  }

  CustomerVoucher? get appliedVoucher {
    final id = _appliedVoucherId;
    if (id == null) {
      return null;
    }
    return CustomerVoucherStore.instance.voucherById(id);
  }

  double get subtotal {
    return _items.fold(
      0,
      (sum, item) => sum + item.lineTotal,
    );
  }

  double get deliveryFee {
    return cartServiceType == 'delivery' ? 19.99 : 0.0;
  }

  double get serviceFee => isEmpty ? 0.0 : 7.50;

  double get memberDeliverySaving {
    return previewMember && cartServiceType == 'delivery' ? deliveryFee : 0.0;
  }

  double get rewardDiscount {
    if (CustomerRewardsStore.instance.usesApi) {
      return 0;
    }
    final reward = appliedReward;
    if (reward == null || !isRewardApplicable(reward)) {
      return 0;
    }

    final definition = CustomerRewardsStore.instance.definitionFor(
      reward.definitionId,
    );

    switch (definition.benefitType) {
      case RewardBenefitType.freeDrink:
        final eligible = _eligibleDrinkItems();
        if (eligible.isEmpty) {
          return 0;
        }
        final cheapest = eligible
            .map((item) => item.unitPrice)
            .reduce((a, b) => a < b ? a : b);
        return cheapest.clamp(0, definition.maximumSaving).toDouble();
      case RewardBenefitType.freeSizeUpgrade:
        return _items.any(
          (item) => item.productType.isBeverage && item.size == 'Large',
        )
            ? definition.maximumSaving
            : 0;
    }
  }

  double get voucherDiscount {
    if (CustomerVoucherStore.instance.usesApi) {
      return 0;
    }
    final voucher = appliedVoucher;
    if (voucher == null || !isVoucherApplicable(voucher)) {
      return 0;
    }

    final remainingProductSubtotal = subtotal - rewardDiscount;
    if (remainingProductSubtotal <= 0) {
      return 0;
    }

    return voucher.discountAmount.clamp(0, remainingProductSubtotal).toDouble();
  }

  bool get hasConsistentOrderContext {
    if (_items.isEmpty) {
      return true;
    }
    final first = _items.first;
    return _items.every(
      (item) =>
          item.branchId == first.branchId &&
          item.branchName == first.branchName &&
          item.serviceType == first.serviceType &&
          item.currency == first.currency,
    );
  }

  double totalBeforeTip({
    double tip = 0,
  }) {
    final total = subtotal +
        deliveryFee +
        serviceFee +
        tip -
        memberDeliverySaving -
        rewardDiscount -
        voucherDiscount;
    return total < 0 ? 0 : total;
  }

  void setOrderContext({
    required int branchId,
    required String branchName,
    required String serviceType,
    required double userLatitude,
    required double userLongitude,
  }) {
    _currentBranchId = branchId;
    _currentBranchName = branchName;
    _currentServiceType = serviceType;
    _userLatitude = userLatitude;
    _userLongitude = userLongitude;
    unawaited(_persist());
  }

  bool canAccept(CartItem item) {
    if (_items.isEmpty) {
      return true;
    }

    final first = _items.first;

    return first.branchId == item.branchId &&
        first.branchName == item.branchName &&
        first.serviceType == item.serviceType &&
        first.currency == item.currency;
  }

  bool containsSignature(String signature) {
    return _items.any(
      (item) => item.signature == signature,
    );
  }

  bool isRewardApplicable(RedeemedReward reward) {
    if (_items.isEmpty || reward.status == RewardRedemptionStatus.used) {
      return false;
    }

    if (CustomerRewardsStore.instance.usesApi) {
      return reward.code.trim().isNotEmpty;
    }

    final definition = CustomerRewardsStore.instance.definitionFor(
      reward.definitionId,
    );

    switch (definition.benefitType) {
      case RewardBenefitType.freeDrink:
        return _eligibleDrinkItems().isNotEmpty;
      case RewardBenefitType.freeSizeUpgrade:
        return _items.any(
          (item) => item.productType.isBeverage && item.size == 'Large',
        );
    }
  }

  String rewardIneligibilityReason(RedeemedReward reward) {
    if (_items.isEmpty) {
      return 'Add an eligible item to your cart before applying this reward.';
    }
    if (CustomerRewardsStore.instance.usesApi) {
      return reward.code.trim().isEmpty
          ? 'This reward has no active Laravel voucher to apply.'
          : 'Laravel will verify this reward against the current checkout.';
    }

    final definition = CustomerRewardsStore.instance.definitionFor(
      reward.definitionId,
    );

    switch (definition.benefitType) {
      case RewardBenefitType.freeDrink:
        return 'This reward needs an eligible drink in the cart.';
      case RewardBenefitType.freeSizeUpgrade:
        return 'Choose Large on an eligible drink to use the free size upgrade.';
    }
  }

  bool isVoucherApplicable(CustomerVoucher voucher) {
    if (_items.isEmpty ||
        voucher.status == VoucherStatus.used ||
        voucher.status == VoucherStatus.expired ||
        voucher.expiresAt.isBefore(DateTime.now())) {
      return false;
    }

    if (CustomerVoucherStore.instance.usesApi) {
      return voucher.code.trim().isNotEmpty;
    }

    return subtotal >= voucher.minimumSpend;
  }

  String voucherIneligibilityReason(CustomerVoucher voucher) {
    if (_items.isEmpty) {
      return 'Add items to your cart before applying this voucher.';
    }
    if (CustomerVoucherStore.instance.usesApi) {
      return voucher.code.trim().isEmpty
          ? 'This server voucher has no usable code.'
          : 'Laravel will verify this voucher against the current checkout.';
    }
    if (voucher.status == VoucherStatus.expired ||
        voucher.expiresAt.isBefore(DateTime.now())) {
      return 'This voucher has expired and cannot be applied.';
    }
    if (voucher.status == VoucherStatus.used) {
      return 'This voucher has already been used.';
    }
    if (subtotal < voucher.minimumSpend) {
      final remaining = voucher.minimumSpend - subtotal;
      return 'Add EGP ${remaining.toStringAsFixed(remaining == remaining.roundToDouble() ? 0 : 2)} more to reach the EGP ${voucher.minimumSpend.toStringAsFixed(voucher.minimumSpend == voucher.minimumSpend.roundToDouble() ? 0 : 2)} minimum spend.';
    }
    return 'This voucher is not eligible for the current cart.';
  }

  VoucherApplyResult applyVoucherByCode(String code) {
    final voucher = CustomerVoucherStore.instance.voucherByCode(code);
    if (voucher == null) {
      return VoucherApplyResult.notFound;
    }
    return applyVoucher(voucher.id);
  }

  VoucherApplyResult applyVoucher(String voucherId) {
    final vouchers = CustomerVoucherStore.instance;
    final voucher = vouchers.voucherById(voucherId);

    if (_items.isEmpty) {
      return VoucherApplyResult.emptyCart;
    }
    if (voucher == null) {
      return VoucherApplyResult.notFound;
    }
    if (voucher.status == VoucherStatus.expired ||
        voucher.expiresAt.isBefore(DateTime.now())) {
      return VoucherApplyResult.expired;
    }
    if (voucher.status == VoucherStatus.used) {
      return VoucherApplyResult.used;
    }
    if (!vouchers.usesApi && subtotal < voucher.minimumSpend) {
      return VoucherApplyResult.minimumSpendNotMet;
    }

    if (vouchers.usesApi && appliedReward != null) {
      final reward = appliedReward!;
      CustomerRewardsStore.instance.markAvailable(reward.id);
      _appliedRewardId = null;
    }

    final previous = appliedVoucher;
    if (previous != null && previous.id != voucher.id) {
      vouchers.markAvailable(previous.id);
    }

    _appliedVoucherId = voucher.id;
    vouchers.markApplied(voucher.id);
    notifyListeners();
    unawaited(_persist());
    return VoucherApplyResult.success;
  }

  void removeVoucher() {
    final voucher = appliedVoucher;
    if (voucher == null) {
      return;
    }

    CustomerVoucherStore.instance.markAvailable(voucher.id);
    _appliedVoucherId = null;
    notifyListeners();
    unawaited(_persist());
  }

  bool applyReward(String redemptionId) {
    final rewards = CustomerRewardsStore.instance;
    final redemption = rewards.redeemedById(redemptionId);

    if (redemption == null || !isRewardApplicable(redemption)) {
      return false;
    }

    if (rewards.usesApi && appliedVoucher != null) {
      final voucher = appliedVoucher!;
      CustomerVoucherStore.instance.markAvailable(voucher.id);
      _appliedVoucherId = null;
    }

    final previous = appliedReward;
    if (previous != null && previous.id != redemption.id) {
      rewards.markAvailable(previous.id);
    }

    _appliedRewardId = redemption.id;
    rewards.markApplied(redemption.id);
    notifyListeners();
    unawaited(_persist());
    return true;
  }

  void removeReward() {
    final reward = appliedReward;
    if (reward == null) {
      return;
    }

    CustomerRewardsStore.instance.markAvailable(reward.id);
    _appliedRewardId = null;
    notifyListeners();
    unawaited(_persist());
  }

  bool addOrMerge(CartItem item) {
    if (!canAccept(item)) {
      return false;
    }

    final index = _items.indexWhere(
      (existing) => existing.signature == item.signature,
    );

    if (index == -1) {
      _items.add(item);
    } else {
      final existing = _items[index];
      _items[index] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
    }

    _validateAppliedReward();
    _validateAppliedVoucher();
    notifyListeners();
    unawaited(_persist());
    return true;
  }

  void replaceItem({
    required String originalSignature,
    required CartItem replacement,
  }) {
    final originalIndex = _items.indexWhere(
      (item) => item.signature == originalSignature,
    );

    if (originalIndex == -1) {
      addOrMerge(replacement);
      return;
    }

    _items.removeAt(originalIndex);

    final mergeIndex = _items.indexWhere(
      (item) => item.signature == replacement.signature,
    );

    if (mergeIndex == -1) {
      _items.insert(originalIndex, replacement);
    } else {
      final existing = _items[mergeIndex];
      _items[mergeIndex] = existing.copyWith(
        quantity: existing.quantity + replacement.quantity,
      );
    }

    _validateAppliedReward();
    _validateAppliedVoucher();
    notifyListeners();
    unawaited(_persist());
  }

  void setQuantity(
    String signature,
    int quantity,
  ) {
    final index = _items.indexWhere(
      (item) => item.signature == signature,
    );

    if (index == -1) {
      return;
    }

    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(
        quantity: quantity,
      );
    }

    _validateAppliedReward();
    _validateAppliedVoucher();
    _cleanupOrderMetadataIfEmpty();
    notifyListeners();
    unawaited(_persist());
  }

  void remove(String signature) {
    _items.removeWhere(
      (item) => item.signature == signature,
    );
    _validateAppliedReward();
    _validateAppliedVoucher();
    _cleanupOrderMetadataIfEmpty();
    notifyListeners();
    unawaited(_persist());
  }

  void clear() {
    if (_items.isEmpty &&
        _specialRequest.isEmpty &&
        _appliedRewardId == null &&
        _appliedVoucherId == null) {
      return;
    }

    final reward = appliedReward;
    if (reward != null) {
      CustomerRewardsStore.instance.markAvailable(reward.id);
    }

    final voucher = appliedVoucher;
    if (voucher != null) {
      CustomerVoucherStore.instance.markAvailable(voucher.id);
    }

    _items.clear();
    _specialRequest = '';
    _appliedRewardId = null;
    _appliedVoucherId = null;
    notifyListeners();
    unawaited(_persist());
  }

  void completeServerOrder() {
    // Server-side loyalty/voucher/gift-card state must be refreshed from Laravel.
    // Never mark local demo benefits as consumed for a production order.
    _items.clear();
    _specialRequest = '';
    _appliedRewardId = null;
    _appliedVoucherId = null;
    notifyListeners();
    unawaited(_persist());
  }

  void completeDemoOrder() {
    final reward = appliedReward;
    if (reward != null) {
      CustomerRewardsStore.instance.markUsed(reward.id);
    }

    final voucher = appliedVoucher;
    if (voucher != null) {
      CustomerVoucherStore.instance.markUsed(voucher.id);
    }

    _items.clear();
    _specialRequest = '';
    _appliedRewardId = null;
    _appliedVoucherId = null;
    notifyListeners();
    unawaited(_persist());
  }

  void setSpecialRequest(String value) {
    _specialRequest = value;
    unawaited(_persist());
  }

  void _cleanupOrderMetadataIfEmpty() {
    if (_items.isNotEmpty) {
      return;
    }
    _specialRequest = '';
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) return;

    if (_items.isEmpty &&
        _specialRequest.isEmpty &&
        _appliedRewardId == null &&
        _appliedVoucherId == null) {
      await preferences.remove(_storageKey);
      return;
    }

    await preferences.setString(
      _storageKey,
      jsonEncode(<String, dynamic>{
        'version': 3,
        'items': _items.map((item) => item.toJson()).toList(growable: false),
        'currentBranchId': _currentBranchId,
        'currentBranchName': _currentBranchName,
        'currentServiceType': _currentServiceType,
        'userLatitude': _userLatitude,
        'userLongitude': _userLongitude,
        'specialRequest': _specialRequest,
        'appliedRewardId': _appliedRewardId,
        'appliedVoucherId': _appliedVoucherId,
      }),
    );
  }

  @visibleForTesting
  Future<void> reloadFromStorageForTesting() async {
    _preferences ??= await SharedPreferences.getInstance();
    _initialized = true;
    _items.clear();
    _specialRequest = '';
    _appliedRewardId = null;
    _appliedVoucherId = null;
    await _restore();
  }

  List<CartItem> _eligibleDrinkItems() {
    return _items
        .where(
          (item) => item.productType.isBeverage,
        )
        .toList(growable: false);
  }

  void _validateAppliedReward() {
    final reward = appliedReward;
    if (reward == null || isRewardApplicable(reward)) {
      return;
    }

    CustomerRewardsStore.instance.markAvailable(reward.id);
    _appliedRewardId = null;
  }

  void _validateAppliedVoucher() {
    final voucher = appliedVoucher;
    if (voucher == null || isVoucherApplicable(voucher)) {
      return;
    }

    CustomerVoucherStore.instance.markAvailable(voucher.id);
    _appliedVoucherId = null;
  }
}
