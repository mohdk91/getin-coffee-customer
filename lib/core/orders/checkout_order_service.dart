import 'checkout_order_draft.dart';

/// Order boundary used by Checkout.
///
/// Replace [DemoCheckoutOrderService] with a Laravel-backed implementation
/// later without moving order-creation responsibility back into the UI.
abstract class CheckoutOrderService {
  Future<CheckoutOrderResult> createOrder(CheckoutOrderDraft draft);
}

class CheckoutOrderResult {
  final bool success;
  final String? orderId;
  final int? apiOrderId;
  final String? orderNumber;
  final String? total;
  final String? currency;
  final String? status;
  final String? paymentStatus;
  final DateTime? placedAt;
  final String message;

  const CheckoutOrderResult._({
    required this.success,
    required this.orderId,
    this.apiOrderId,
    this.orderNumber,
    this.total,
    this.currency,
    this.status,
    this.paymentStatus,
    this.placedAt,
    required this.message,
  });

  const CheckoutOrderResult.success({
    required String orderId,
    String message = 'Demo order created successfully.',
  }) : this._(
          success: true,
          orderId: orderId,
          message: message,
        );

  const CheckoutOrderResult.server({
    required int apiOrderId,
    required String orderNumber,
    required String total,
    required String currency,
    required String status,
    required String paymentStatus,
    DateTime? placedAt,
    String message = 'Order created successfully.',
  }) : this._(
          success: true,
          orderId: orderNumber,
          apiOrderId: apiOrderId,
          orderNumber: orderNumber,
          total: total,
          currency: currency,
          status: status,
          paymentStatus: paymentStatus,
          placedAt: placedAt,
          message: message,
        );

  const CheckoutOrderResult.failure(String message)
      : this._(
          success: false,
          orderId: null,
          message: message,
        );
}

class DemoCheckoutOrderService implements CheckoutOrderService {
  DemoCheckoutOrderService._();

  static final DemoCheckoutOrderService instance = DemoCheckoutOrderService._();

  bool _failNextRequest = false;

  @override
  Future<CheckoutOrderResult> createOrder(CheckoutOrderDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (_failNextRequest) {
      _failNextRequest = false;
      return const CheckoutOrderResult.failure(
        'Demo order creation failed. Your cart has been kept unchanged.',
      );
    }

    if (draft.lines.isEmpty) {
      return const CheckoutOrderResult.failure(
        'The order cannot be created because the cart is empty.',
      );
    }

    if (draft.isDelivery && draft.deliveryAddress == null) {
      return const CheckoutOrderResult.failure(
        'Choose a delivery address before placing the order.',
      );
    }

    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    final shortSuffix = suffix.substring(suffix.length - 6);

    return CheckoutOrderResult.success(
      orderId: 'DEMO-$shortSuffix',
    );
  }

  /// Test-only hook used to verify that a failed create-order attempt never
  /// clears the cart or consumes rewards/vouchers/store credit.
  void failNextRequestForTesting() {
    _failNextRequest = true;
  }
}
