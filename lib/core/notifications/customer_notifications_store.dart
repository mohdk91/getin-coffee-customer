import 'package:flutter/foundation.dart';

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
  bool get usesApi => _repository?.usesApi ?? false;
  int get unreadCount => usesApi
      ? _serverUnreadCount
      : _items.where((item) => !item.isRead).length;

  static Future<void> initialize(CustomerRepositoryContext context) async {
    instance._repository = CustomerEngagementApiRepository(context);
    if (instance.usesApi) {
      await instance.refresh();
    } else {
      instance._items = _demoItems;
    }
  }

  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null || !repository.usesApi) {
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
    if (repository != null && repository.usesApi) {
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
    if (repository != null && repository.usesApi) {
      await repository.markAllNotificationsRead();
      _serverUnreadCount = 0;
    }
    _items = _items.map((item) => item.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  static final List<CustomerNotificationItem> _demoItems =
      <CustomerNotificationItem>[
    CustomerNotificationItem(
      id: 1,
      type: 'delivery',
      title: 'Your order is on the way',
      body: 'Your GETIN delivery is on the way.',
      isRead: false,
      createdAt: DateTime(2026, 9, 30),
    ),
    CustomerNotificationItem(
      id: 2,
      type: 'loyalty',
      title: 'Stars earned',
      body: 'Stars from your latest eligible order were added.',
      isRead: false,
      createdAt: DateTime(2026, 9, 29),
    ),
  ];
}
