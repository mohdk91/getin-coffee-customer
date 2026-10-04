import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/customer_auth_store.dart';
import '../data/customer_repository.dart';
import '../engagement/customer_engagement_api_repository.dart';

@immutable
class CustomerNotificationItem {
  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
  final String? actionRoute;

  const CustomerNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
    this.actionRoute,
  });

  CustomerNotificationItem copyWith({bool? isRead}) => CustomerNotificationItem(
        id: id,
        type: type,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        actionRoute: actionRoute,
      );

  factory CustomerNotificationItem.fromApi(Map<String, dynamic> json) {
    return CustomerNotificationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? 'GETIN',
      body: json['body']?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      actionRoute: json['action_route']?.toString(),
    );
  }
}

class CustomerNotificationsStore extends ChangeNotifier {
  CustomerNotificationsStore._();

  static final CustomerNotificationsStore instance =
      CustomerNotificationsStore._();

  CustomerEngagementApiRepository? _repository;
  List<CustomerNotificationItem> _items = const <CustomerNotificationItem>[];
  bool _loading = false;
  int _serverUnreadCount = 0;

  List<CustomerNotificationItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;

  /// True only when notifications are backed by an authenticated GETIN
  /// account. Signed-out production users receive the polished guest preview
  /// instead of an empty/technical error state.
  bool get usesApi =>
      (_repository?.usesApi ?? false) &&
      CustomerAuthStore.instance.isAuthenticated;

  int get unreadCount => usesApi
      ? _serverUnreadCount
      : _items.where((item) => !item.isRead).length;

  static Future<void> initialize(CustomerRepositoryContext context) async {
    final store = instance;
    store._repository = CustomerEngagementApiRepository(context);
    CustomerAuthStore.instance.removeListener(store._handleAuthChanged);
    CustomerAuthStore.instance.addListener(store._handleAuthChanged);

    if (store.usesApi) {
      await store.refresh();
    } else {
      store._loadGuestPreview();
    }
  }

  void _handleAuthChanged() {
    if (usesApi) {
      unawaited(refresh());
      return;
    }
    _loadGuestPreview();
  }

  void _loadGuestPreview() {
    _items = _guestPreviewItems();
    _serverUnreadCount = 0;
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null || !usesApi) {
      if (!CustomerAuthStore.instance.isAuthenticated) {
        _loadGuestPreview();
      }
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final items = await repository.notifications();
      final unreadCount = await repository.notificationUnreadCount();
      _items = items.map(CustomerNotificationItem.fromApi).toList();
      _serverUnreadCount = unreadCount;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(int id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0 || _items[index].isRead) {
      return;
    }

    final repository = _repository;
    if (repository != null && usesApi) {
      await repository.markNotificationRead(id);
      if (_serverUnreadCount > 0) {
        _serverUnreadCount -= 1;
      }
    }
    _items = <CustomerNotificationItem>[
      for (var i = 0; i < _items.length; i++)
        i == index ? _items[i].copyWith(isRead: true) : _items[i],
    ];
    notifyListeners();
  }

  Future<void> markAllRead() async {
    final repository = _repository;
    if (repository != null && usesApi) {
      await repository.markAllNotificationsRead();
      _serverUnreadCount = 0;
    }
    _items = _items.map((item) => item.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  static List<CustomerNotificationItem> _guestPreviewItems() {
    final now = DateTime.now();
    return <CustomerNotificationItem>[
      CustomerNotificationItem(
        id: -1,
        type: 'order',
        title: 'Order confirmed',
        body: 'Your GETIN order is confirmed and the branch is preparing it.',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 8)),
        actionRoute: 'orders',
      ),
      CustomerNotificationItem(
        id: -2,
        type: 'delivery',
        title: 'Your order is on the way',
        body: 'Your driver has picked up the order and is heading to you.',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        actionRoute: 'orders',
      ),
      CustomerNotificationItem(
        id: -3,
        type: 'loyalty',
        title: '18 Stars added',
        body: 'Stars from your completed Iced Latte order are now available.',
        isRead: false,
        createdAt: now.subtract(const Duration(days: 1)),
        actionRoute: 'rewards',
      ),
      CustomerNotificationItem(
        id: -4,
        type: 'stamp',
        title: 'Stamp collected · 3 of 7',
        body: 'Four more eligible drinks unlock your next free drink.',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
        actionRoute: 'rewards',
      ),
      CustomerNotificationItem(
        id: -5,
        type: 'offer',
        title: 'Breakfast Picks are ready',
        body: 'Pair your coffee with a fresh bakery favourite today.',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
        actionRoute: 'menu',
      ),
      CustomerNotificationItem(
        id: -6,
        type: 'reward',
        title: 'A reward is waiting',
        body: 'Check your Stars and available GETIN rewards.',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3)),
        actionRoute: 'rewards',
      ),
      CustomerNotificationItem(
        id: -7,
        type: 'membership',
        title: 'Discover GETIN Membership',
        body: 'See member benefits, tier progress and Stars earning.',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 4)),
        actionRoute: 'membership',
      ),
      CustomerNotificationItem(
        id: -8,
        type: 'voucher',
        title: 'Your next coffee can cost less',
        body: 'Open Rewards to see benefits you can use on your next order.',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 5)),
        actionRoute: 'rewards',
      ),
    ];
  }
}
