import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/customer_repository.dart';
import '../engagement/customer_engagement_api_repository.dart';

@immutable
class CustomerReviewSlotStatus {
  final bool eligible;
  final bool submitted;
  final String? reason;

  const CustomerReviewSlotStatus({
    required this.eligible,
    required this.submitted,
    required this.reason,
  });

  factory CustomerReviewSlotStatus.fromJson(Map<String, dynamic> json) {
    final reason = json['reason']?.toString().trim() ?? '';
    return CustomerReviewSlotStatus(
      eligible: json['eligible'] as bool? ?? false,
      submitted: json['submitted'] as bool? ?? false,
      reason: reason.isEmpty ? null : reason,
    );
  }
}

@immutable
class CustomerOrderReviewStatus {
  final int orderId;
  final String orderNumber;
  final String orderType;
  final String status;
  final CustomerReviewSlotStatus delivery;
  final CustomerReviewSlotStatus employee;

  const CustomerOrderReviewStatus({
    required this.orderId,
    required this.orderNumber,
    required this.orderType,
    required this.status,
    required this.delivery,
    required this.employee,
  });

  bool get hasEligibleReview => delivery.eligible || employee.eligible;
  bool get hasSubmittedReview => delivery.submitted || employee.submitted;

  factory CustomerOrderReviewStatus.fromJson(Map<String, dynamic> json) {
    final order = json['order'] is Map
        ? Map<String, dynamic>.from(json['order'] as Map)
        : const <String, dynamic>{};
    final delivery = json['delivery'] is Map
        ? Map<String, dynamic>.from(json['delivery'] as Map)
        : const <String, dynamic>{};
    final employee = json['employee'] is Map
        ? Map<String, dynamic>.from(json['employee'] as Map)
        : const <String, dynamic>{};

    return CustomerOrderReviewStatus(
      orderId: (order['id'] as num?)?.toInt() ?? 0,
      orderNumber: order['order_number']?.toString() ?? '',
      orderType: order['order_type']?.toString() ?? '',
      status: order['status']?.toString() ?? '',
      delivery: CustomerReviewSlotStatus.fromJson(delivery),
      employee: CustomerReviewSlotStatus.fromJson(employee),
    );
  }
}

@immutable
class CustomerProductReview {
  final String id;
  final String productName;
  final String reviewerName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final bool verifiedPurchase;
  final String? orderId;

  const CustomerProductReview({
    required this.id,
    required this.productName,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.verifiedPurchase = true,
    this.orderId,
  });

  factory CustomerProductReview.fromJson(Map<String, dynamic> json) {
    return CustomerProductReview(
      id: json['id'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      reviewerName: json['reviewerName'] as String? ?? 'Customer',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      verifiedPurchase: json['verifiedPurchase'] as bool? ?? true,
      orderId: json['orderId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'productName': productName,
        'reviewerName': reviewerName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'verifiedPurchase': verifiedPurchase,
        'orderId': orderId,
      };
}

@immutable
class CustomerDriverReview {
  final String id;
  final String orderId;
  final String driverName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const CustomerDriverReview({
    required this.id,
    required this.orderId,
    required this.driverName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory CustomerDriverReview.fromJson(Map<String, dynamic> json) {
    return CustomerDriverReview(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      driverName: json['driverName'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'orderId': orderId,
        'driverName': driverName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };
}

@immutable
class CustomerServiceReview {
  final String id;
  final String orderId;
  final String kind;
  final String subjectName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const CustomerServiceReview({
    required this.id,
    required this.orderId,
    required this.kind,
    required this.subjectName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory CustomerServiceReview.fromJson(Map<String, dynamic> json) {
    return CustomerServiceReview(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'orderId': orderId,
        'kind': kind,
        'subjectName': subjectName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };
}

class CustomerReviewStore extends ChangeNotifier {
  CustomerReviewStore._();

  static final CustomerReviewStore instance = CustomerReviewStore._();
  static const String _productStorageKey =
      'getin_demo_submitted_product_reviews_v1';
  static const String _driverStorageKey =
      'getin_demo_submitted_driver_reviews_v1';
  static const String _serviceStorageKey =
      'getin_demo_submitted_service_reviews_v1';

  SharedPreferences? _preferences;
  CustomerEngagementApiRepository? _repository;
  bool _initialized = false;

  bool get usesApi => _repository?.usesApi ?? false;

  final List<CustomerProductReview> _submittedProductReviews = [];
  final List<CustomerDriverReview> _submittedDriverReviews = [];
  final List<CustomerServiceReview> _submittedServiceReviews = [];
  final Map<int, CustomerOrderReviewStatus> _orderStatuses =
      <int, CustomerOrderReviewStatus>{};

  static Future<void> initialize([CustomerRepositoryContext? context]) =>
      instance._initialize(context);

  Future<void> _initialize([CustomerRepositoryContext? context]) async {
    if (_initialized) {
      return;
    }
    if (context != null) {
      _repository = CustomerEngagementApiRepository(context);
    }
    _initialized = true;
    if (usesApi) {
      await _refreshApi();
      return;
    }
    _preferences = await SharedPreferences.getInstance();
    _load();
  }

  Future<void> _refreshApi() async {
    final repository = _repository;
    if (repository == null || !repository.usesApi) {
      return;
    }
    final items = await repository.reviews();
    _submittedProductReviews.clear();
    _submittedDriverReviews.clear();
    _submittedServiceReviews.clear();
    for (final item in items) {
      final type = item['type']?.toString();
      final order = item['order'];
      final orderId = order is Map ? order['id']?.toString() ?? '' : '';
      final createdAt =
          DateTime.tryParse(item['submitted_at']?.toString() ?? '') ??
              DateTime.now();
      if (type == 'delivery') {
        final driver = item['driver'];
        _submittedDriverReviews.add(CustomerDriverReview(
          id: item['id']?.toString() ?? '',
          orderId: orderId,
          driverName:
              driver is Map ? driver['name']?.toString() ?? 'Driver' : 'Driver',
          rating: (item['rating'] as num?)?.toInt() ?? 0,
          comment: item['comment']?.toString() ?? '',
          createdAt: createdAt,
        ));
      } else if (type == 'employee') {
        final employee = item['employee'];
        final ratings = item['ratings'];
        _submittedServiceReviews.add(CustomerServiceReview(
          id: item['id']?.toString() ?? '',
          orderId: orderId,
          kind: 'employee',
          subjectName: employee is Map
              ? employee['name']?.toString() ?? 'Employee'
              : 'Employee',
          rating:
              ratings is Map ? (ratings['overall'] as num?)?.toInt() ?? 0 : 0,
          comment: item['comment']?.toString() ?? '',
          createdAt: createdAt,
        ));
      }
    }
    notifyListeners();
  }

  CustomerOrderReviewStatus? statusForOrder(int orderId) =>
      _orderStatuses[orderId];

  Future<CustomerOrderReviewStatus?> loadOrderStatus(
    int orderId, {
    bool force = false,
  }) async {
    final repository = _repository;
    if (repository == null || !repository.usesApi || orderId <= 0) {
      return null;
    }
    if (!force && _orderStatuses.containsKey(orderId)) {
      return _orderStatuses[orderId];
    }

    final raw = await repository.orderReviewStatus(orderId);
    final status = CustomerOrderReviewStatus.fromJson(raw);
    _orderStatuses[orderId] = status;
    notifyListeners();
    return status;
  }

  Future<void> refreshLiveHistory() async {
    if (!usesApi) return;
    await _refreshApi();
  }

  Future<bool> submitLiveDeliveryReview({
    required int orderId,
    required int rating,
    required String comment,
  }) async {
    if (!usesApi || orderId <= 0) return false;
    final status = await loadOrderStatus(orderId, force: true);
    if (status?.delivery.eligible != true) {
      return false;
    }

    await _repository!.submitDeliveryReview(
      orderId: orderId,
      rating: rating,
      comment: comment,
    );
    await _refreshApi();
    final refreshed = await loadOrderStatus(orderId, force: true);
    return refreshed?.delivery.submitted == true;
  }

  Future<bool> submitLiveReview({
    required String orderId,
    required int rating,
    required String comment,
    String? driverName,
    String? employeeName,
    String? branchName,
    String? productName,
  }) async {
    if (!usesApi) {
      return false;
    }
    final numericOrderId = int.tryParse(orderId);
    if (numericOrderId == null) {
      return false;
    }
    if (driverName != null) {
      return submitLiveDeliveryReview(
        orderId: numericOrderId,
        rating: rating,
        comment: comment,
      );
    } else if (employeeName != null) {
      await _repository!.submitEmployeeReview(
        orderId: numericOrderId,
        rating: rating,
        comment: comment,
      );
    } else {
      return false;
    }
    await _refreshApi();
    return true;
  }

  void _load() {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    _submittedProductReviews
      ..clear()
      ..addAll(
          _decodeProductReviews(preferences.getString(_productStorageKey)));
    _submittedDriverReviews
      ..clear()
      ..addAll(_decodeDriverReviews(preferences.getString(_driverStorageKey)));
    _submittedServiceReviews
      ..clear()
      ..addAll(
          _decodeServiceReviews(preferences.getString(_serviceStorageKey)));
    notifyListeners();
  }

  List<CustomerProductReview> reviewsFor(String productName) {
    return [
      ..._submittedProductReviews.where(
        (review) => review.productName == productName,
      ),
      if (!usesApi) ..._seededReviewsFor(productName),
    ];
  }

  List<CustomerDriverReview> get driverReviews =>
      List.unmodifiable(_submittedDriverReviews);
  List<CustomerServiceReview> get serviceReviews =>
      List.unmodifiable(_submittedServiceReviews);

  double averageRating(String productName) {
    final reviews = reviewsFor(productName);
    if (reviews.isEmpty) {
      return 0;
    }
    final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }

  Map<int, int> ratingDistribution(String productName) {
    final result = <int, int>{
      for (var rating = 1; rating <= 5; rating++) rating: 0
    };
    for (final review in reviewsFor(productName)) {
      result[review.rating] = (result[review.rating] ?? 0) + 1;
    }
    return result;
  }

  bool hasProductReview({
    required String orderId,
    required String productName,
  }) {
    return _submittedProductReviews.any(
      (review) =>
          review.orderId == orderId && review.productName == productName,
    );
  }

  bool hasDriverReview(String orderId) {
    return _submittedDriverReviews.any((review) => review.orderId == orderId);
  }

  CustomerProductReview? submittedReviewFor({
    required String orderId,
    required String productName,
  }) {
    for (final review in _submittedProductReviews) {
      if (review.orderId == orderId && review.productName == productName) {
        return review;
      }
    }
    return null;
  }

  CustomerDriverReview? driverReviewFor(String orderId) {
    for (final review in _submittedDriverReviews) {
      if (review.orderId == orderId) {
        return review;
      }
    }
    return null;
  }

  bool hasServiceReview({
    required String orderId,
    required String kind,
  }) {
    return _submittedServiceReviews.any(
      (review) => review.orderId == orderId && review.kind == kind,
    );
  }

  CustomerServiceReview? serviceReviewFor({
    required String orderId,
    required String kind,
  }) {
    for (final review in _submittedServiceReviews) {
      if (review.orderId == orderId && review.kind == kind) {
        return review;
      }
    }
    return null;
  }

  void submitProductReview({
    required String orderId,
    required String productName,
    required int rating,
    required String comment,
    String reviewerName = 'Mohammed',
  }) {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Rating must be 1–5.');
    }
    if (hasProductReview(orderId: orderId, productName: productName)) {
      return;
    }

    _submittedProductReviews.insert(
      0,
      CustomerProductReview(
        id: 'review-${DateTime.now().microsecondsSinceEpoch}',
        productName: productName,
        reviewerName: reviewerName,
        rating: rating,
        comment: comment.trim(),
        createdAt: DateTime.now(),
        orderId: orderId,
      ),
    );
    notifyListeners();
    unawaited(_persist());
  }

  void submitDriverReview({
    required String orderId,
    required String driverName,
    required int rating,
    required String comment,
  }) {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Rating must be 1–5.');
    }
    if (hasDriverReview(orderId)) {
      return;
    }

    _submittedDriverReviews.insert(
      0,
      CustomerDriverReview(
        id: 'driver-review-${DateTime.now().microsecondsSinceEpoch}',
        orderId: orderId,
        driverName: driverName,
        rating: rating,
        comment: comment.trim(),
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    unawaited(_persist());
  }

  void submitServiceReview({
    required String orderId,
    required String kind,
    required String subjectName,
    required int rating,
    required String comment,
  }) {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Rating must be 1–5.');
    }
    if (hasServiceReview(orderId: orderId, kind: kind)) {
      return;
    }

    _submittedServiceReviews.insert(
      0,
      CustomerServiceReview(
        id: 'service-review-${DateTime.now().microsecondsSinceEpoch}',
        orderId: orderId,
        kind: kind,
        subjectName: subjectName,
        rating: rating,
        comment: comment.trim(),
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    unawaited(_persist());
  }

  @visibleForTesting
  void clearSubmittedReviews() {
    _submittedProductReviews.clear();
    _submittedDriverReviews.clear();
    _submittedServiceReviews.clear();
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    await preferences.setString(
      _productStorageKey,
      jsonEncode(
        _submittedProductReviews.map((review) => review.toJson()).toList(),
      ),
    );
    await preferences.setString(
      _driverStorageKey,
      jsonEncode(
        _submittedDriverReviews.map((review) => review.toJson()).toList(),
      ),
    );
    await preferences.setString(
      _serviceStorageKey,
      jsonEncode(
        _submittedServiceReviews.map((review) => review.toJson()).toList(),
      ),
    );
  }

  List<CustomerProductReview> _decodeProductReviews(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <CustomerProductReview>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <CustomerProductReview>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (entry) => CustomerProductReview.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .where(
            (review) =>
                review.id.isNotEmpty &&
                review.productName.isNotEmpty &&
                review.rating >= 1 &&
                review.rating <= 5,
          )
          .toList(growable: false);
    } catch (_) {
      return <CustomerProductReview>[];
    }
  }

  List<CustomerDriverReview> _decodeDriverReviews(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <CustomerDriverReview>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <CustomerDriverReview>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (entry) => CustomerDriverReview.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .where(
            (review) =>
                review.id.isNotEmpty &&
                review.orderId.isNotEmpty &&
                review.rating >= 1 &&
                review.rating <= 5,
          )
          .toList(growable: false);
    } catch (_) {
      return <CustomerDriverReview>[];
    }
  }

  List<CustomerServiceReview> _decodeServiceReviews(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <CustomerServiceReview>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <CustomerServiceReview>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (entry) => CustomerServiceReview.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .where(
            (review) =>
                review.id.isNotEmpty &&
                review.orderId.isNotEmpty &&
                review.kind.isNotEmpty &&
                review.rating >= 1 &&
                review.rating <= 5,
          )
          .toList(growable: false);
    } catch (_) {
      return <CustomerServiceReview>[];
    }
  }

  @visibleForTesting
  Future<void> reloadFromStorageForTesting() async {
    _preferences ??= await SharedPreferences.getInstance();
    _initialized = true;
    _load();
  }

  List<CustomerProductReview> _seededReviewsFor(String productName) {
    final normalized = productName.toLowerCase();
    final isFood =
        normalized.contains('turkey') || normalized.contains('sandwich');
    final isBakery = normalized.contains('muffin') ||
        normalized.contains('croissant') ||
        normalized.contains('bakery');
    final isMerchandise = normalized.contains('tumbler') ||
        normalized.contains('mug') ||
        normalized.contains('bottle');

    final comments = isFood
        ? const [
            'Fresh, warm and very filling. I would order this again.',
            'Good balance of turkey and cheese, and it arrived neatly packed.',
            'Tasted fresh and the portion was right for a quick lunch.',
            'Simple and reliable. The warm option works really well.',
          ]
        : isBakery
            ? const [
                'Soft inside and nicely warmed. Great with coffee.',
                'Fresh texture and not overly sweet.',
                'A very good quick breakfast add-on.',
                'Arrived fresh and held up well during delivery.',
              ]
            : isMerchandise
                ? const [
                    'Feels sturdy and the finish looks premium.',
                    'Useful size and easy to carry every day.',
                    'The lid fits well and the color looks great in person.',
                    'A practical Getin item with a clean design.',
                  ]
                : const [
                    'Balanced, smooth and exactly what I expected from Getin.',
                    'Very consistent taste and it arrived at the right temperature.',
                    'One of my regular orders. The customization options are useful.',
                    'Fresh and well prepared. I would order it again.',
                  ];

    const ratings = [5, 5, 4, 5];
    const names = ['Nour', 'Omar', 'Mariam', 'Youssef'];
    final now = DateTime(2026, 9, 20);

    return List.generate(
      comments.length,
      (index) => CustomerProductReview(
        id: 'seed-${productName.hashCode}-$index',
        productName: productName,
        reviewerName: names[index],
        rating: ratings[index],
        comment: comments[index],
        createdAt: now.subtract(Duration(days: index + 1)),
        verifiedPurchase: true,
      ),
    );
  }
}
