import '../data/customer_repository.dart';
import 'customer_checkout_api_repository.dart';

class LiveCheckoutQuoteItem {
  final int productId;
  final int? variantId;
  final List<int> optionValueIds;
  final int quantity;

  const LiveCheckoutQuoteItem({
    required this.productId,
    required this.variantId,
    required this.optionValueIds,
    required this.quantity,
  });

  Map<String, dynamic> toApiPayload() => <String, dynamic>{
        'product_id': productId,
        if (variantId != null) 'variant_id': variantId,
        if (optionValueIds.isNotEmpty)
          'option_value_ids': List<int>.unmodifiable(optionValueIds),
        'quantity': quantity,
      };
}

class LiveCheckoutQuote {
  final bool checkoutReady;
  final List<String> reasons;
  final String currency;
  final double subtotal;
  final double discountTotal;
  final double deliveryFee;
  final double taxTotal;
  final double total;
  final String? promotionCode;
  final String? promotionName;
  final String? promotionKind;
  final double promotionDiscount;
  final int? giftCardId;
  final String? giftCardLastFour;
  final double giftCardBalance;
  final double giftCardApplied;
  final double amountDue;

  const LiveCheckoutQuote({
    required this.checkoutReady,
    required this.reasons,
    required this.currency,
    required this.subtotal,
    required this.discountTotal,
    required this.deliveryFee,
    required this.taxTotal,
    required this.total,
    required this.promotionCode,
    required this.promotionName,
    required this.promotionKind,
    required this.promotionDiscount,
    required this.giftCardId,
    required this.giftCardLastFour,
    required this.giftCardBalance,
    required this.giftCardApplied,
    required this.amountDue,
  });

  factory LiveCheckoutQuote.fromResponse(Map<String, dynamic> response) {
    final rawData = response['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : const <String, dynamic>{};
    final rawPricing = data['pricing'];
    final pricing = rawPricing is Map
        ? Map<String, dynamic>.from(rawPricing)
        : const <String, dynamic>{};
    final rawPromotion = pricing['promotion'];
    final promotion = rawPromotion is Map
        ? Map<String, dynamic>.from(rawPromotion)
        : const <String, dynamic>{};
    final rawGiftCard = data['gift_card'];
    final giftCard = rawGiftCard is Map
        ? Map<String, dynamic>.from(rawGiftCard)
        : const <String, dynamic>{};

    double amount(String key) =>
        double.tryParse(pricing[key]?.toString() ?? '') ?? 0;

    return LiveCheckoutQuote(
      checkoutReady: data['checkout_ready'] == true,
      reasons: (data['reasons'] as List? ?? const <dynamic>[])
          .map((value) => value.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false),
      currency: pricing['currency']?.toString() ?? '',
      subtotal: amount('subtotal'),
      discountTotal: amount('discount_total'),
      deliveryFee: amount('delivery_fee'),
      taxTotal: amount('tax_total'),
      total: amount('total'),
      promotionCode: promotion['code']?.toString(),
      promotionName: promotion['name']?.toString(),
      promotionKind: promotion['kind']?.toString(),
      promotionDiscount:
          double.tryParse(promotion['discount_amount']?.toString() ?? '') ?? 0,
      giftCardId: (giftCard['id'] as num?)?.toInt(),
      giftCardLastFour: giftCard['last_four']?.toString(),
      giftCardBalance:
          double.tryParse(giftCard['balance']?.toString() ?? '') ?? 0,
      giftCardApplied:
          double.tryParse(giftCard['applied']?.toString() ?? '') ?? 0,
      amountDue: double.tryParse(
            data['amount_due']?.toString() ?? pricing['total']?.toString() ?? '',
          ) ??
          amount('total'),
    );
  }
}

class LiveCheckoutQuoteService {
  final CustomerCheckoutApiRepository repository;

  LiveCheckoutQuoteService(CustomerRepositoryContext context)
      : repository = CustomerCheckoutApiRepository(context);

  Future<LiveCheckoutQuote> quote({
    required int branchId,
    required String orderType,
    required List<LiveCheckoutQuoteItem> items,
    int? addressId,
    String? promotionCode,
    int? giftCardId,
  }) async {
    final response = await repository.quoteCheckout(
      branchId: branchId,
      payload: buildPayload(
        orderType: orderType,
        items: items,
        addressId: addressId,
        promotionCode: promotionCode,
        giftCardId: giftCardId,
      ),
    );
    return LiveCheckoutQuote.fromResponse(response);
  }

  static Map<String, dynamic> buildPayload({
    required String orderType,
    required List<LiveCheckoutQuoteItem> items,
    int? addressId,
    String? promotionCode,
    int? giftCardId,
  }) {
    if (orderType != 'pickup' && orderType != 'delivery') {
      throw ArgumentError.value(orderType, 'orderType');
    }
    if (items.isEmpty) {
      throw ArgumentError('Live checkout quote requires at least one item.');
    }
    if (orderType == 'delivery' && (addressId == null || addressId <= 0)) {
      throw StateError('A numeric saved address is required for delivery.');
    }

    return <String, dynamic>{
      'order_type': orderType,
      'items': items.map((item) => item.toApiPayload()).toList(growable: false),
      if (orderType == 'delivery') 'address_id': addressId,
      if (promotionCode != null && promotionCode.trim().isNotEmpty)
        'coupon_code': promotionCode.trim(),
      if (giftCardId != null && giftCardId > 0) 'gift_card_id': giftCardId,
    };
  }
}
