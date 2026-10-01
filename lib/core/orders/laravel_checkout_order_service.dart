import '../data/customer_repository.dart';
import '../network/api_exception.dart';
import 'checkout_order_draft.dart';
import 'checkout_order_service.dart';
import 'customer_checkout_api_repository.dart';

/// Production checkout boundary.
///
/// Laravel remains authoritative for prices, availability, discounts and
/// totals. This service sends only stable catalog identities plus quantity,
/// asks Laravel for a checkout-ready quote, and creates the order using the
/// same idempotency key carried by [CheckoutOrderDraft].
class LaravelCheckoutOrderService implements CheckoutOrderService {
  final CustomerCheckoutApiRepository repository;

  LaravelCheckoutOrderService(CustomerRepositoryContext context)
      : repository = CustomerCheckoutApiRepository(context);

  @override
  Future<CheckoutOrderResult> createOrder(CheckoutOrderDraft draft) async {
    try {
      final branchId = draft.branchId;
      if (branchId == null || branchId <= 0) {
        return const CheckoutOrderResult.failure(
          'The selected branch is missing its server identity. Refresh the menu and try again.',
        );
      }

      final quotePayload = buildServerPayload(draft, includePayment: false);
      final quoteResponse = await repository.quoteCheckout(
        branchId: branchId,
        payload: quotePayload,
      );
      final quote = _data(quoteResponse);
      if (quote['checkout_ready'] != true) {
        final reasons = (quote['reasons'] as List? ?? const <dynamic>[])
            .map((value) => value.toString())
            .where((value) => value.trim().isNotEmpty)
            .toList(growable: false);
        return CheckoutOrderResult.failure(
          reasons.isEmpty
              ? 'Laravel could not confirm that this checkout is ready.'
              : 'Checkout is not ready: ${reasons.join(', ')}.',
        );
      }

      final createResponse = await repository.createOrder(
        branchId: branchId,
        delivery: draft.isDelivery,
        payload: buildServerPayload(draft, includePayment: true),
        idempotencyKey: draft.clientRequestId,
      );
      final order = _data(createResponse);
      final apiOrderId = (order['id'] as num?)?.toInt();
      final orderNumber = order['order_number']?.toString();
      final total = order['total']?.toString();
      final currency = order['currency']?.toString();
      final status = order['status']?.toString();
      final paymentStatus = order['payment_status']?.toString();

      if (apiOrderId == null ||
          apiOrderId <= 0 ||
          orderNumber == null ||
          orderNumber.trim().isEmpty ||
          total == null ||
          currency == null ||
          status == null ||
          paymentStatus == null) {
        return const CheckoutOrderResult.failure(
          'Laravel created an order response that the app could not verify. Refresh Orders before retrying.',
        );
      }

      return CheckoutOrderResult.server(
        apiOrderId: apiOrderId,
        orderNumber: orderNumber,
        total: total,
        currency: currency,
        status: status,
        paymentStatus: paymentStatus,
        placedAt: DateTime.tryParse(order['placed_at']?.toString() ?? ''),
        message: createResponse['message']?.toString() ?? 'Order created successfully.',
      );
    } on ApiException catch (error) {
      return CheckoutOrderResult.failure(error.message);
    }
  }

  /// Builds the only payload accepted by production checkout/order creation.
  /// Client-side monetary fields are deliberately excluded.
  static Map<String, dynamic> buildServerPayload(
    CheckoutOrderDraft draft, {
    required bool includePayment,
  }) {
    final branchId = draft.branchId;
    if (branchId == null || branchId <= 0) {
      throw StateError('A numeric branch ID is required for live checkout.');
    }

    final items = draft.lines.map((line) {
      final productId = line.productId;
      if (productId == null || productId <= 0) {
        throw StateError(
          'Every live checkout line must contain a numeric product ID.',
        );
      }

      return <String, dynamic>{
        'product_id': productId,
        if (line.variantId != null) 'variant_id': line.variantId,
        if (line.optionValueIds.isNotEmpty)
          'option_value_ids': List<int>.unmodifiable(line.optionValueIds),
        'quantity': line.quantity,
      };
    }).toList(growable: false);

    final payload = <String, dynamic>{
      'order_type': draft.serviceType,
      'items': items,
    };

    if (draft.isDelivery) {
      final addressId = int.tryParse(draft.deliveryAddress?.id ?? '');
      if (addressId == null || addressId <= 0) {
        throw StateError(
          'A server-backed saved address is required for live delivery checkout.',
        );
      }
      payload['address_id'] = addressId;
    }

    if (includePayment) {
      payload['payment_method'] = 'card';
      if (draft.specialRequest.trim().isNotEmpty) {
        payload['customer_notes'] = draft.specialRequest.trim();
      }
    }

    return payload;
  }

  static Map<String, dynamic> _data(Map<String, dynamic> response) {
    final raw = response['data'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }
}
