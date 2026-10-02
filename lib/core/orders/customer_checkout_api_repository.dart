import '../data/customer_repository.dart';

class CustomerCheckoutApiRepository {
  final CustomerRepositoryContext context;
  const CustomerCheckoutApiRepository(this.context);

  bool get usesApi => context.usesApi;

  Future<Map<String, dynamic>> validateCart({required int branchId, required Map<String, dynamic> payload}) =>
      context.apiClient.postJson('/api/v1/customer/branches/$branchId/cart/validate', body: payload, authenticated: true);

  Future<Map<String, dynamic>> quoteCheckout({required int branchId, required Map<String, dynamic> payload}) =>
      context.apiClient.postJson('/api/v1/customer/branches/$branchId/checkout/quote', body: payload, authenticated: true);

  Future<Map<String, dynamic>> deliveryEligibility(Map<String, dynamic> payload) =>
      context.apiClient.postJson('/api/v1/customer/delivery/eligibility', body: payload, authenticated: true);

  Future<Map<String, dynamic>> paymentMethods() =>
      context.apiClient.getJson('/api/v1/customer/payment-methods', authenticated: true);


  Future<Map<String, dynamic>> createPaymentSetupSession({required String idempotencyKey}) =>
      context.apiClient.requestJson(
        'POST',
        '/api/v1/customer/payment-methods/setup-session',
        authenticated: true,
        retryable: true,
        headers: <String, String>{'Idempotency-Key': idempotencyKey},
      );

  Future<Map<String, dynamic>> deletePaymentMethod({
    required String paymentMethodId,
    required String idempotencyKey,
  }) =>
      context.apiClient.requestJson(
        'DELETE',
        '/api/v1/customer/payment-methods/$paymentMethodId',
        authenticated: true,
        retryable: true,
        headers: <String, String>{'Idempotency-Key': idempotencyKey},
      );

  Future<Map<String, dynamic>> setDefaultPaymentMethod({
    required String paymentMethodId,
    required String idempotencyKey,
  }) =>
      context.apiClient.requestJson(
        'POST',
        '/api/v1/customer/payment-methods/$paymentMethodId/default',
        authenticated: true,
        retryable: true,
        headers: <String, String>{'Idempotency-Key': idempotencyKey},
      );

  Future<Map<String, dynamic>> createPaymentSession({
    required int branchId,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) =>
      context.apiClient.requestJson(
        'POST',
        '/api/v1/customer/branches/$branchId/checkout/payment-session',
        body: payload,
        authenticated: true,
        retryable: true,
        headers: <String, String>{'Idempotency-Key': idempotencyKey},
      );

  Future<Map<String, dynamic>> validateCoupon({required int branchId, required String code, required Map<String, dynamic> pricingPayload}) {
    return context.apiClient.postJson('/api/v1/customer/branches/$branchId/coupons/validate', body: <String,dynamic>{...pricingPayload, 'coupon_code': code}, authenticated: true);
  }

  Future<Map<String, dynamic>> validateVoucher({required int voucherId, required Map<String, dynamic> payload}) =>
      context.apiClient.postJson('/api/v1/customer/vouchers/$voucherId/validate', body: payload, authenticated: true);

  Future<Map<String, dynamic>> createOrder({
    required int branchId,
    required bool delivery,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) {
    final path = delivery
        ? '/api/v1/customer/branches/$branchId/orders/delivery'
        : '/api/v1/customer/branches/$branchId/orders/pickup';
    return context.apiClient.requestJson(
      'POST', path,
      body: payload,
      authenticated: true,
      retryable: true,
      headers: <String,String>{'Idempotency-Key': idempotencyKey},
    );
  }
}
