/// Immutable checkout snapshot prepared for the future Laravel order API.
///
/// The draft contains only order/payment references and tokenized payment
/// identifiers. It never contains a raw card number or CVV.
class CheckoutOrderDraft {
  final String clientRequestId;
  final DateTime createdAt;
  final int? branchId;
  final String branchName;
  final String serviceType;
  final String currency;
  final List<CheckoutOrderLine> lines;
  final int itemCount;
  final String specialRequest;
  final CheckoutDeliveryAddress? deliveryAddress;
  final String? deliveryInstruction;
  final String fulfilmentEstimate;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double tip;
  final double membershipSaving;
  final double rewardSaving;
  final String? rewardRedemptionId;
  final double voucherSaving;
  final String? voucherCode;
  final double giftCardApplied;
  final int? giftCardId;
  final String paymentTender;
  final String? paymentMethodId;
  final String? paymentTokenReference;
  final double total;

  const CheckoutOrderDraft({
    required this.clientRequestId,
    required this.createdAt,
    required this.branchId,
    required this.branchName,
    required this.serviceType,
    required this.currency,
    required this.lines,
    required this.itemCount,
    required this.specialRequest,
    required this.deliveryAddress,
    required this.deliveryInstruction,
    required this.fulfilmentEstimate,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.tip,
    required this.membershipSaving,
    required this.rewardSaving,
    required this.rewardRedemptionId,
    required this.voucherSaving,
    required this.voucherCode,
    required this.giftCardApplied,
    this.giftCardId,
    required this.paymentTender,
    required this.paymentMethodId,
    required this.paymentTokenReference,
    required this.total,
  });

  bool get isDelivery => serviceType == 'delivery';

  Map<String, dynamic> toApiPayload() => <String, dynamic>{
        'branch_id': branchId,
        'client_request_id': clientRequestId,
        'created_at': createdAt.toIso8601String(),
        'branch_name': branchName,
        'service_type': serviceType,
        'currency': currency,
        'items': lines.map((line) => line.toApiPayload()).toList(),
        'special_request': specialRequest,
        'delivery_address': deliveryAddress?.toApiPayload(),
        'delivery_instruction': deliveryInstruction,
        'fulfilment_estimate': fulfilmentEstimate,
        'pricing': <String, dynamic>{
          'subtotal': subtotal,
          'delivery_fee': deliveryFee,
          'service_fee': serviceFee,
          'tip': tip,
          'membership_saving': membershipSaving,
          'reward_saving': rewardSaving,
          'voucher_saving': voucherSaving,
          'gift_card_applied': giftCardApplied,
          'total': total,
        },
        'reward_redemption_id': rewardRedemptionId,
        'voucher_code': voucherCode,
        'payment': <String, dynamic>{
          'tender': paymentTender,
          'payment_method_id': paymentMethodId,
          'payment_token_reference': paymentTokenReference,
        },
      };
}

class CheckoutOrderLine {
  final int? productId;
  final int? variantId;
  final List<int> optionValueIds;
  final String name;
  final String productType;
  final String description;
  final String image;
  final double basePrice;
  final double unitPrice;
  final int quantity;
  final String? size;
  final String? temperature;
  final String? milk;
  final String strength;
  final String sweetness;
  final List<String> addOns;
  final String? variant;
  final String? warming;
  final String? sauce;
  final String? color;

  const CheckoutOrderLine({
    required this.productId,
    required this.variantId,
    required this.optionValueIds,
    required this.name,
    required this.productType,
    required this.description,
    required this.image,
    required this.basePrice,
    required this.unitPrice,
    required this.quantity,
    required this.size,
    required this.temperature,
    required this.milk,
    required this.strength,
    required this.sweetness,
    required this.addOns,
    required this.variant,
    required this.warming,
    required this.sauce,
    required this.color,
  });

  Map<String, dynamic> toApiPayload() => <String, dynamic>{
        'product_id': productId,
        'variant_id': variantId,
        'option_value_ids': optionValueIds,
        'name': name,
        'product_type': productType,
        'description': description,
        'image': image,
        'base_price': basePrice,
        'unit_price': unitPrice,
        'quantity': quantity,
        'configuration': <String, dynamic>{
          'size': size,
          'temperature': temperature,
          'milk': milk,
          'strength': strength,
          'sweetness': sweetness,
          'add_ons': addOns,
          'variant': variant,
          'warming': warming,
          'sauce': sauce,
          'color': color,
        },
      };
}

class CheckoutDeliveryAddress {
  final String id;
  final String label;
  final String area;
  final String city;
  final String building;
  final String floor;
  final String apartment;
  final double latitude;
  final double longitude;

  const CheckoutDeliveryAddress({
    required this.id,
    required this.label,
    required this.area,
    required this.city,
    required this.building,
    required this.floor,
    required this.apartment,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toApiPayload() => <String, dynamic>{
        'id': id,
        'label': label,
        'area': area,
        'city': city,
        'building': building,
        'floor': floor,
        'apartment': apartment,
        'latitude': latitude,
        'longitude': longitude,
      };
}
