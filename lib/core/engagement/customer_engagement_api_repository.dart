import '../data/customer_repository.dart';
import '../network/api_exception.dart';

class CustomerEngagementApiRepository {
  final CustomerRepositoryContext context;

  const CustomerEngagementApiRepository(this.context);

  bool get usesApi => context.usesApi;

  Future<Map<String, dynamic>> loyalty() => _getMap('/v1/customer/loyalty');

  Future<List<Map<String, dynamic>>> loyaltyTransactions() =>
      _getItems('/v1/customer/loyalty/transactions');

  Future<Map<String, dynamic>> membership() =>
      _getMap('/v1/customer/membership');

  Future<List<Map<String, dynamic>>> membershipTiers() =>
      _getItems('/v1/customer/membership/tiers');

  Future<List<Map<String, dynamic>>> rewards() =>
      _getItems('/v1/customer/rewards');

  Future<List<Map<String, dynamic>>> rewardRedemptions() =>
      _getItems('/v1/customer/reward-redemptions');

  Future<Map<String, dynamic>> redeemReward(int rewardId) async {
    final payload = await context.apiClient.requestJson(
      'POST',
      '/v1/customer/rewards/$rewardId/redeem',
      authenticated: true,
      headers: _idempotencyHeaders('reward-$rewardId'),
    );
    return _dataMap(payload);
  }

  Future<List<Map<String, dynamic>>> stampCards() =>
      _getItems('/v1/customer/stamp-cards');

  Future<Map<String, dynamic>> referralProgram() =>
      _getMap('/v1/customer/referral');

  Future<List<Map<String, dynamic>>> referrals() =>
      _getItems('/v1/customer/referrals');

  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    final payload = await context.apiClient.requestJson(
      'POST',
      '/v1/customer/referral/apply',
      authenticated: true,
      body: <String, dynamic>{'code': code.trim()},
    );
    return _dataMap(payload);
  }

  Future<List<Map<String, dynamic>>> vouchers() =>
      _getItems('/v1/customer/vouchers');

  Future<Map<String, dynamic>> validateVoucher(int voucherId) =>
      _getMap('/v1/customer/vouchers/$voucherId/validate');

  Future<List<Map<String, dynamic>>> giftCards() =>
      _getItems('/v1/customer/gift-cards');

  Future<Map<String, dynamic>> claimGiftCard(String code) async {
    final payload = await context.apiClient.requestJson(
      'POST',
      '/v1/customer/gift-cards/claim',
      authenticated: true,
      headers: _idempotencyHeaders('gift-claim'),
      body: <String, dynamic>{'code': code.trim()},
    );
    return _dataMap(payload);
  }

  Future<Map<String, dynamic>> giftCardBalance(String code) async {
    final payload = await context.apiClient.requestJson(
      'POST',
      '/v1/customer/gift-cards/balance',
      authenticated: true,
      body: <String, dynamic>{'code': code.trim()},
    );
    return _dataMap(payload);
  }

  Future<List<Map<String, dynamic>>> giftCardTransactions(int giftCardId) =>
      _getItems('/v1/customer/gift-cards/$giftCardId/transactions');

  Future<Map<String, dynamic>> playStatus() => _getMap('/v1/customer/play');

  Future<Map<String, dynamic>> playAttempt({String? deviceFingerprint}) async {
    final payload = await context.apiClient.requestJson(
      'POST',
      '/v1/customer/play/attempt',
      authenticated: true,
      headers: _idempotencyHeaders('play'),
      body: <String, dynamic>{
        if (deviceFingerprint != null && deviceFingerprint.trim().isNotEmpty)
          'device_fingerprint': deviceFingerprint.trim(),
      },
    );
    return _dataMap(payload);
  }

  Future<List<Map<String, dynamic>>> playHistory() =>
      _getItems('/v1/customer/play/history');

  Future<List<Map<String, dynamic>>> reviews() =>
      _getItems('/v1/customer/reviews');

  Future<Map<String, dynamic>> orderReviewStatus(int orderId) =>
      _getMap('/v1/customer/orders/$orderId/reviews');

  Future<Map<String, dynamic>> submitDeliveryReview({
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    final payload = await context.apiClient.requestJson(
      'POST',
      '/v1/customer/orders/$orderId/delivery-review',
      authenticated: true,
      body: <String, dynamic>{
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    return _dataMap(payload);
  }

  Future<Map<String, dynamic>> submitEmployeeReview({
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    final payload = await context.apiClient.requestJson(
      'POST',
      '/v1/customer/orders/$orderId/employee-review',
      authenticated: true,
      body: <String, dynamic>{
        'cleanliness_rating': rating,
        'appearance_rating': rating,
        'treatment_rating': rating,
        'service_rating': rating,
        'overall_rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    return _dataMap(payload);
  }

  Future<List<Map<String, dynamic>>> notifications() =>
      _getItems('/v1/customer/notifications');

  Future<int> notificationUnreadCount() async {
    final data = await _getMap('/v1/customer/notifications/unread-count');
    return (data['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, dynamic>> markNotificationRead(int id) async {
    final payload = await context.apiClient.requestJson(
      'POST',
      '/v1/customer/notifications/$id/read',
      authenticated: true,
    );
    return _dataMap(payload);
  }

  Future<void> markAllNotificationsRead() async {
    await context.apiClient.requestJson(
      'POST',
      '/v1/customer/notifications/read-all',
      authenticated: true,
    );
  }

  Future<List<Map<String, dynamic>>> conversations() =>
      _getItems('/v1/customer/conversations');

  Future<Map<String, dynamic>> conversation(int id) =>
      _getMap('/v1/customer/conversations/$id');

  Future<Map<String, dynamic>> openDriverChat(int orderId) async {
    final payload = await context.apiClient.requestJson(
      'POST',
      '/v1/customer/orders/$orderId/driver-chat',
      authenticated: true,
    );
    return _dataMap(payload);
  }

  Future<Map<String, dynamic>> openSupportChat({
    required String subject,
    int? orderId,
  }) async {
    final payload = await context.apiClient.requestJson(
      'POST',
      '/v1/customer/support-conversations',
      authenticated: true,
      body: <String, dynamic>{
        'subject': subject.trim().isEmpty ? 'Customer support' : subject.trim(),
        if (orderId != null) 'order_id': orderId,
      },
    );
    return _dataMap(payload);
  }

  Future<Map<String, dynamic>> sendConversationMessage({
    required int conversationId,
    required String body,
  }) async {
    final payload = await context.apiClient.requestJson(
      'POST',
      '/v1/customer/conversations/$conversationId/messages',
      authenticated: true,
      body: <String, dynamic>{'body': body.trim()},
    );
    return _dataMap(payload);
  }

  Future<void> markConversationRead(int conversationId,
      {int? messageId}) async {
    await context.apiClient.requestJson(
      'POST',
      '/v1/customer/conversations/$conversationId/read',
      authenticated: true,
      body: <String, dynamic>{if (messageId != null) 'message_id': messageId},
    );
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final payload = await context.apiClient.getJson(path, authenticated: true);
    return _dataMap(payload);
  }

  Future<List<Map<String, dynamic>>> _getItems(String path) async {
    final data = await _getMap(path);
    final raw = data['items'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    if (data.isEmpty) return const <Map<String, dynamic>>[];
    throw const ApiException(
        'We couldn’t load this information. Please try again.');
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException(
        'We couldn’t load your rewards activity. Please try again.');
  }

  Map<String, String> _idempotencyHeaders(String scope) => <String, String>{
        'Idempotency-Key':
            'customer-$scope-${DateTime.now().microsecondsSinceEpoch}',
      };
}
