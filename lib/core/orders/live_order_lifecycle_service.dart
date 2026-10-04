import '../data/customer_repository.dart';
import '../network/api_exception.dart';
import 'customer_orders_api_repository.dart';
import 'live_order_models.dart';

class LiveOrderLifecycleService {
  final CustomerOrdersApiRepository _repository;

  LiveOrderLifecycleService(CustomerRepositoryContext context)
      : _repository = CustomerOrdersApiRepository(context);

  bool get usesApi => _repository.usesApi;

  Future<LiveOrderDetail> loadOrder(int orderId) async {
    final payload = await _repository.detail(orderId);
    return LiveOrderDetail.fromJson(_dataMap(payload));
  }

  Future<List<LiveOrderTimelineEntry>> loadDeliveryTimeline(int orderId) async {
    final payload = await _repository.timeline(orderId);
    final data = payload['data'];
    if (data is! List) {
      throw const ApiException(
          'We couldn’t load the order timeline. Please try again.');
    }
    return data
        .whereType<Map>()
        .map((entry) => LiveOrderTimelineEntry.fromDeliveryEvent(
              Map<String, dynamic>.from(entry),
            ))
        .toList(growable: false);
  }

  Future<LiveOrderDetail> cancelOrder({
    required int orderId,
    required String reason,
  }) async {
    final payload = await _repository.cancel(
      orderId,
      reason.trim(),
      _idempotencyKey('cancel', orderId),
    );
    return LiveOrderDetail.fromJson(_dataMap(payload));
  }

  Future<LiveRefundRequest> requestRefund({
    required int orderId,
    required String reason,
  }) async {
    final payload = await _repository.refund(
      orderId,
      reason.trim(),
      _idempotencyKey('refund', orderId),
    );
    return LiveRefundRequest.fromJson(_dataMap(payload));
  }

  Future<LiveDeliveryPin> issueDeliveryPin(int orderId) async {
    final payload = await _repository.issuePin(
      orderId,
      _idempotencyKey('delivery-pin', orderId),
    );
    return LiveDeliveryPin.fromJson(_dataMap(payload));
  }

  Future<LiveDeliveryQr> issueDeliveryQr(int orderId) async {
    final payload = await _repository.issueQr(
      orderId,
      _idempotencyKey('delivery-qr', orderId),
    );
    return LiveDeliveryQr.fromJson(_dataMap(payload));
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('We couldn’t load this order. Please try again.');
  }

  String _idempotencyKey(String action, int orderId) {
    return 'customer-order-$orderId-$action-${DateTime.now().microsecondsSinceEpoch}';
  }
}
