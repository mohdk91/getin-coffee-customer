import '../data/customer_repository.dart';
import '../network/api_exception.dart';
import 'customer_orders_api_repository.dart';

class LiveDriverTrackingSnapshot {
  final int orderId;
  final String state;
  final bool available;
  final String? reason;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final DateTime? recordedAt;
  final DateTime? receivedAt;
  final int? ageSeconds;
  final bool? isFresh;
  final bool? isAccurate;
  final int? maxStaleSeconds;
  final double? maxAccuracyMeters;
  final double? destinationLatitude;
  final double? destinationLongitude;

  const LiveDriverTrackingSnapshot({
    required this.orderId,
    required this.state,
    required this.available,
    required this.reason,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.recordedAt,
    required this.receivedAt,
    required this.ageSeconds,
    required this.isFresh,
    required this.isAccurate,
    required this.maxStaleSeconds,
    required this.maxAccuracyMeters,
    required this.destinationLatitude,
    required this.destinationLongitude,
  });

  bool get hasPosition => latitude != null && longitude != null;
  bool get isTerminal => state == 'terminal';
  bool get shouldPoll => !isTerminal;

  factory LiveDriverTrackingSnapshot.fromJson(Map<String, dynamic> json) {
    final position = json['position'] is Map
        ? Map<String, dynamic>.from(json['position'] as Map)
        : const <String, dynamic>{};
    final quality = json['quality'] is Map
        ? Map<String, dynamic>.from(json['quality'] as Map)
        : const <String, dynamic>{};
    final destination = json['destination'] is Map
        ? Map<String, dynamic>.from(json['destination'] as Map)
        : const <String, dynamic>{};

    return LiveDriverTrackingSnapshot(
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      state: json['state']?.toString() ?? 'waiting_gps',
      available: json['available'] == true,
      reason: _text(json['reason']),
      latitude: _double(position['latitude']),
      longitude: _double(position['longitude']),
      accuracyMeters: _double(position['accuracy_meters']),
      recordedAt: DateTime.tryParse(position['recorded_at']?.toString() ?? ''),
      receivedAt: DateTime.tryParse(position['received_at']?.toString() ?? ''),
      ageSeconds: (quality['age_seconds'] as num?)?.toInt(),
      isFresh: quality.containsKey('is_fresh') ? quality['is_fresh'] == true : null,
      isAccurate: quality.containsKey('is_accurate')
          ? quality['is_accurate'] == true
          : null,
      maxStaleSeconds: (quality['max_stale_seconds'] as num?)?.toInt(),
      maxAccuracyMeters: _double(quality['max_accuracy_meters']),
      destinationLatitude: _double(destination['latitude']),
      destinationLongitude: _double(destination['longitude']),
    );
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class LiveDriverTrackingRepository {
  final CustomerOrdersApiRepository _orders;

  LiveDriverTrackingRepository(CustomerRepositoryContext context)
      : _orders = CustomerOrdersApiRepository(context);

  bool get usesApi => _orders.usesApi;

  Future<LiveDriverTrackingSnapshot> load(int orderId) async {
    final payload = await _orders.driverLocation(orderId);
    final raw = payload['data'];
    if (raw is Map<String, dynamic>) {
      return LiveDriverTrackingSnapshot.fromJson(raw);
    }
    if (raw is Map) {
      return LiveDriverTrackingSnapshot.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }
    throw const ApiException('GETIN returned invalid driver tracking data.');
  }
}
