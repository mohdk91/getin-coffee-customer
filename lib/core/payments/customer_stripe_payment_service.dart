import 'package:flutter_stripe/flutter_stripe.dart';

import '../data/customer_repository.dart';
import '../network/api_exception.dart';
import '../orders/customer_checkout_api_repository.dart';

class StripeSetupSession {
  final String publishableKey;
  final String customerId;
  final String ephemeralKeySecret;
  final String setupIntentClientSecret;

  const StripeSetupSession({
    required this.publishableKey,
    required this.customerId,
    required this.ephemeralKeySecret,
    required this.setupIntentClientSecret,
  });

  factory StripeSetupSession.fromJson(Map<String, dynamic> json) {
    return StripeSetupSession(
      publishableKey: _requiredText(json, 'publishable_key'),
      customerId: _requiredText(json, 'customer_id'),
      ephemeralKeySecret: _requiredText(json, 'ephemeral_key_secret'),
      setupIntentClientSecret:
          _requiredText(json, 'setup_intent_client_secret'),
    );
  }
}

class StripeCheckoutSession {
  final bool paymentRequired;
  final String? paymentSessionId;
  final String? publishableKey;
  final String? customerId;
  final String? ephemeralKeySecret;
  final String? paymentIntentClientSecret;
  final String currency;
  final String amountDue;

  const StripeCheckoutSession({
    required this.paymentRequired,
    required this.paymentSessionId,
    required this.publishableKey,
    required this.customerId,
    required this.ephemeralKeySecret,
    required this.paymentIntentClientSecret,
    required this.currency,
    required this.amountDue,
  });

  factory StripeCheckoutSession.fromJson(Map<String, dynamic> json) {
    final required = json['payment_required'] == true;
    return StripeCheckoutSession(
      paymentRequired: required,
      paymentSessionId:
          required ? _requiredText(json, 'payment_session_id') : null,
      publishableKey: required ? _requiredText(json, 'publishable_key') : null,
      customerId: required ? _requiredText(json, 'customer_id') : null,
      ephemeralKeySecret:
          required ? _requiredText(json, 'ephemeral_key_secret') : null,
      paymentIntentClientSecret: required
          ? _requiredText(json, 'payment_intent_client_secret')
          : null,
      currency: json['currency']?.toString() ?? '',
      amountDue: json['amount_due']?.toString() ?? '0',
    );
  }
}

class CustomerStripePaymentService {
  final CustomerCheckoutApiRepository _repository;

  CustomerStripePaymentService(CustomerRepositoryContext context)
      : _repository = CustomerCheckoutApiRepository(context);

  Future<StripeSetupSession> createSetupSession() async {
    final response = await _repository.createPaymentSetupSession(
      idempotencyKey: _key('stripe-setup'),
    );
    return StripeSetupSession.fromJson(_data(response));
  }

  Future<StripeCheckoutSession> createCheckoutSession({
    required int branchId,
    required Map<String, dynamic> checkoutPayload,
    required String idempotencyKey,
  }) async {
    final response = await _repository.createPaymentSession(
      branchId: branchId,
      payload: checkoutPayload,
      idempotencyKey: idempotencyKey,
    );
    return StripeCheckoutSession.fromJson(_data(response));
  }

  Future<void> presentSetupSheet(StripeSetupSession session) async {
    await _configure(session.publishableKey);
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'GETIN Coffee',
        customerId: session.customerId,
        customerEphemeralKeySecret: session.ephemeralKeySecret,
        setupIntentClientSecret: session.setupIntentClientSecret,
        allowsDelayedPaymentMethods: false,
        paymentMethodOrder: const <String>['card'],
        cardBrandAcceptance: const CardBrandAcceptance.allowed(
          brands: <CardBrandCategory>[
            CardBrandCategory.visa,
            CardBrandCategory.mastercard,
          ],
        ),
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }

  Future<void> presentCheckoutSheet(StripeCheckoutSession session) async {
    if (!session.paymentRequired) return;
    await _configure(session.publishableKey!);
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'GETIN Coffee',
        customerId: session.customerId,
        customerEphemeralKeySecret: session.ephemeralKeySecret,
        paymentIntentClientSecret: session.paymentIntentClientSecret,
        allowsDelayedPaymentMethods: false,
        paymentMethodOrder: const <String>['card'],
        cardBrandAcceptance: const CardBrandAcceptance.allowed(
          brands: <CardBrandCategory>[
            CardBrandCategory.visa,
            CardBrandCategory.mastercard,
          ],
        ),
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }

  Future<void> _configure(String publishableKey) async {
    if (!publishableKey.startsWith('pk_')) {
      throw const ApiException('GETIN returned an invalid Stripe configuration.');
    }
    if (Stripe.publishableKey != publishableKey) {
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
    }
  }

  static Map<String, dynamic> _data(Map<String, dynamic> response) {
    final raw = response['data'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw const ApiException('GETIN returned invalid Stripe session data.');
  }

  static String _key(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

String _requiredText(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim() ?? '';
  if (value.isEmpty) {
    throw ApiException('GETIN payment response is missing $key.');
  }
  return value;
}
