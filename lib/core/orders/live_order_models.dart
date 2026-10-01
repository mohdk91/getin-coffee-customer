import 'package:flutter/foundation.dart';

@immutable
class LiveOrderItem {
  final int id;
  final int? productId;
  final int? variantId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double optionsTotal;
  final double lineTotal;
  final Map<String, dynamic> options;
  final String? notes;

  const LiveOrderItem({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.optionsTotal,
    required this.lineTotal,
    required this.options,
    required this.notes,
  });

  factory LiveOrderItem.fromJson(Map<String, dynamic> json) {
    return LiveOrderItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['product_id'] as num?)?.toInt(),
      variantId: (json['variant_id'] as num?)?.toInt(),
      productName: json['product_name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: _money(json['unit_price']),
      optionsTotal: _money(json['options_total']),
      lineTotal: _money(json['line_total']),
      options: json['options'] is Map
          ? Map<String, dynamic>.from(json['options'] as Map)
          : const <String, dynamic>{},
      notes: _nullableText(json['notes']),
    );
  }
}

@immutable
class LiveOrderDeliveryAddress {
  final String? recipientName;
  final String? phone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? area;
  final double? latitude;
  final double? longitude;

  const LiveOrderDeliveryAddress({
    this.recipientName,
    this.phone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.area,
    this.latitude,
    this.longitude,
  });

  factory LiveOrderDeliveryAddress.fromJson(Map<String, dynamic> json) {
    return LiveOrderDeliveryAddress(
      recipientName: _nullableText(json['recipient_name']),
      phone: _nullableText(json['phone']),
      addressLine1: _nullableText(json['address_line_1']),
      addressLine2: _nullableText(json['address_line_2']),
      city: _nullableText(json['city']),
      area: _nullableText(json['area']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  String get formatted {
    final parts = <String>[
      if (addressLine1 != null) addressLine1!,
      if (addressLine2 != null) addressLine2!,
      if (area != null) area!,
      if (city != null) city!,
    ];
    return parts.join(', ');
  }
}

@immutable
class LiveOrderTimelineEntry {
  final int? id;
  final String status;
  final String? eventType;
  final String? description;
  final String? fromState;
  final String? toState;
  final String? source;
  final DateTime? occurredAt;

  const LiveOrderTimelineEntry({
    this.id,
    required this.status,
    this.eventType,
    this.description,
    this.fromState,
    this.toState,
    this.source,
    this.occurredAt,
  });

  factory LiveOrderTimelineEntry.fromOrderTimeline(Map<String, dynamic> json) {
    return LiveOrderTimelineEntry(
      status: json['status']?.toString() ?? '',
      occurredAt: DateTime.tryParse(json['at']?.toString() ?? ''),
    );
  }

  factory LiveOrderTimelineEntry.fromDeliveryEvent(Map<String, dynamic> json) {
    final eventType = json['event_type']?.toString() ?? '';
    final toState = _nullableText(json['to_state']);
    return LiveOrderTimelineEntry(
      id: (json['id'] as num?)?.toInt(),
      status: toState ?? eventType,
      eventType: eventType.isEmpty ? null : eventType,
      description: _nullableText(json['description']),
      fromState: _nullableText(json['from_state']),
      toState: toState,
      source: _nullableText(json['source']),
      occurredAt: DateTime.tryParse(json['occurred_at']?.toString() ?? ''),
    );
  }
}

@immutable
class LiveRefundRequest {
  final int id;
  final int orderId;
  final double amount;
  final String currency;
  final String status;
  final String reason;
  final DateTime? requestedAt;

  const LiveRefundRequest({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.reason,
    required this.requestedAt,
  });

  factory LiveRefundRequest.fromJson(Map<String, dynamic> json) {
    return LiveRefundRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      amount: _money(json['amount']),
      currency: json['currency']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      requestedAt: DateTime.tryParse(json['requested_at']?.toString() ?? ''),
    );
  }
}

@immutable
class LiveDeliveryPin {
  final int orderId;
  final String pin;
  final DateTime? expiresAt;
  final int attemptsRemaining;

  const LiveDeliveryPin({
    required this.orderId,
    required this.pin,
    required this.expiresAt,
    required this.attemptsRemaining,
  });

  factory LiveDeliveryPin.fromJson(Map<String, dynamic> json) {
    return LiveDeliveryPin(
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      pin: json['pin']?.toString() ?? '',
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      attemptsRemaining: (json['attempts_remaining'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class LiveDeliveryQr {
  final int orderId;
  final String token;
  final String payload;
  final DateTime? expiresAt;

  const LiveDeliveryQr({
    required this.orderId,
    required this.token,
    required this.payload,
    required this.expiresAt,
  });

  factory LiveDeliveryQr.fromJson(Map<String, dynamic> json) {
    return LiveDeliveryQr(
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      token: json['token']?.toString() ?? '',
      payload: json['qr_payload']?.toString() ?? '',
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    );
  }
}


@immutable
class LiveGiftCardSettlement {
  final int id;
  final String? lastFour;
  final String currency;
  final double applied;
  final double refunded;
  final double netApplied;
  final double amountDue;
  final double? balance;

  const LiveGiftCardSettlement({
    required this.id,
    required this.lastFour,
    required this.currency,
    required this.applied,
    required this.refunded,
    required this.netApplied,
    required this.amountDue,
    required this.balance,
  });

  factory LiveGiftCardSettlement.fromJson(Map<String, dynamic> json) =>
      LiveGiftCardSettlement(
        id: (json['id'] as num?)?.toInt() ?? 0,
        lastFour: _nullableText(json['last_four']),
        currency: json['currency']?.toString() ?? '',
        applied: _money(json['applied']),
        refunded: _money(json['refunded']),
        netApplied: _money(json['net_applied']),
        amountDue: _money(json['amount_due']),
        balance: json['balance'] == null ? null : _money(json['balance']),
      );
}

@immutable
class LiveOrderDetail {
  final int id;
  final String orderNumber;
  final String orderType;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final LiveGiftCardSettlement? giftCard;
  final double amountDue;
  final double subtotal;
  final double discountTotal;
  final double deliveryFee;
  final double taxTotal;
  final double total;
  final String currency;
  final String? customerNotes;
  final String? cancellationReason;
  final int? branchId;
  final String branchName;
  final LiveOrderDeliveryAddress? deliveryAddress;
  final List<LiveOrderItem> items;
  final List<LiveOrderTimelineEntry> timeline;
  final DateTime? placedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const LiveOrderDetail({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.giftCard,
    required this.amountDue,
    required this.subtotal,
    required this.discountTotal,
    required this.deliveryFee,
    required this.taxTotal,
    required this.total,
    required this.currency,
    required this.customerNotes,
    required this.cancellationReason,
    required this.branchId,
    required this.branchName,
    required this.deliveryAddress,
    required this.items,
    required this.timeline,
    required this.placedAt,
    required this.completedAt,
    required this.cancelledAt,
  });

  bool get isDelivery => orderType == 'delivery';
  bool get isTerminal => const <String>{'completed', 'cancelled'}.contains(status);
  bool get mayOfferCancellation => !isTerminal;
  bool get mayOfferRefund =>
      const <String>{'completed', 'cancelled'}.contains(status) &&
      const <String>{'paid', 'partially_refunded'}.contains(paymentStatus);

  factory LiveOrderDetail.fromJson(Map<String, dynamic> json) {
    final branch = json['branch'] is Map
        ? Map<String, dynamic>.from(json['branch'] as Map)
        : const <String, dynamic>{};
    final rawAddress = json['delivery_address'];
    final rawGiftCard = json['gift_card'];
    final rawItems = json['items'];
    final rawTimeline = json['timeline'];

    return LiveOrderDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      orderType: json['order_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      giftCard: rawGiftCard is Map
          ? LiveGiftCardSettlement.fromJson(
              Map<String, dynamic>.from(rawGiftCard),
            )
          : null,
      amountDue: _money(json['amount_due'] ?? json['total']),
      subtotal: _money(json['subtotal']),
      discountTotal: _money(json['discount_total']),
      deliveryFee: _money(json['delivery_fee']),
      taxTotal: _money(json['tax_total']),
      total: _money(json['total']),
      currency: json['currency']?.toString() ?? '',
      customerNotes: _nullableText(json['customer_notes']),
      cancellationReason: _nullableText(json['cancellation_reason']),
      branchId: (branch['id'] as num?)?.toInt(),
      branchName: branch['name']?.toString() ?? 'GETIN',
      deliveryAddress: rawAddress is Map
          ? LiveOrderDeliveryAddress.fromJson(
              Map<String, dynamic>.from(rawAddress),
            )
          : null,
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => LiveOrderItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const <LiveOrderItem>[],
      timeline: rawTimeline is List
          ? rawTimeline
              .whereType<Map>()
              .map((item) => LiveOrderTimelineEntry.fromOrderTimeline(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const <LiveOrderTimelineEntry>[],
      placedAt: DateTime.tryParse(json['placed_at']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? ''),
      cancelledAt: DateTime.tryParse(json['cancelled_at']?.toString() ?? ''),
    );
  }
}

double _money(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

String? _nullableText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
