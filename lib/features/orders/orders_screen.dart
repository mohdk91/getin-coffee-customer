import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/reviews/customer_review_store.dart';
import '../../core/theme/app_colors.dart';
import '../auth/sign_in_screen.dart';
import '../auth/sign_up_screen.dart';
import '../location/models/branch.dart';
import '../reviews/review_screens.dart';
import 'order_detail_screen.dart';

enum OrderFilter {
  all,
  active,
  completed,
  cancelled,
}

enum GetinOrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

class GetinOrder {
  final String id;
  final DateTime placedAt;
  final String branchName;
  final String fulfillment;
  final GetinOrderStatus status;
  final int itemCount;
  final String total;
  final List<String> itemImages;
  final List<ReviewableProduct> reviewProducts;
  final String? driverName;
  final String? employeeName;
  final String? eta;
  final String? deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryCode;

  const GetinOrder({
    required this.id,
    required this.placedAt,
    required this.branchName,
    required this.fulfillment,
    required this.status,
    required this.itemCount,
    required this.total,
    required this.itemImages,
    this.reviewProducts = const [],
    this.driverName,
    this.employeeName,
    this.eta,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryCode,
  });

  bool get isActive {
    return status == GetinOrderStatus.pending ||
        status == GetinOrderStatus.confirmed ||
        status == GetinOrderStatus.preparing ||
        status == GetinOrderStatus.ready ||
        status == GetinOrderStatus.outForDelivery;
  }

  static GetinOrderStatus statusFromApi(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'pending':
        return GetinOrderStatus.pending;
      case 'confirmed':
      case 'accepted':
        return GetinOrderStatus.confirmed;
      case 'preparing':
      case 'processing':
        return GetinOrderStatus.preparing;
      case 'ready':
      case 'ready_for_pickup':
        return GetinOrderStatus.ready;
      case 'out_for_delivery':
      case 'on_the_way':
        return GetinOrderStatus.outForDelivery;
      case 'completed':
      case 'delivered':
      case 'collected':
        return GetinOrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return GetinOrderStatus.cancelled;
      default:
        return GetinOrderStatus.pending;
    }
  }

  factory GetinOrder.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? '';
    final status = GetinOrderStatus.values.any((value) => value.name == statusName)
        ? GetinOrderStatus.values.firstWhere((value) => value.name == statusName)
        : GetinOrder.statusFromApi(statusName);
    final rawImages = json['itemImages'];
    final rawProducts = json['reviewProducts'];

    return GetinOrder(
      id: json['id'] as String? ?? '',
      placedAt: DateTime.tryParse(json['placedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      branchName: json['branchName'] as String? ?? '',
      fulfillment: json['fulfillment'] as String? ?? 'Delivery',
      status: status,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      total: json['total'] as String? ?? '',
      itemImages: rawImages is List
          ? rawImages.whereType<String>().toList(growable: false)
          : const <String>[],
      reviewProducts: rawProducts is List
          ? rawProducts
              .whereType<Map>()
              .map(
                (entry) => ReviewableProduct(
                  name: entry['name'] as String? ?? '',
                  description: entry['description'] as String? ?? '',
                  image: entry['image'] as String? ?? '',
                  price: entry['price'] as String? ?? '',
                ),
              )
              .where((product) => product.name.isNotEmpty)
              .toList(growable: false)
          : const <ReviewableProduct>[],
      driverName: json['driverName'] as String?,
      employeeName: json['employeeName'] as String?,
      eta: json['eta'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
      deliveryCode: json['deliveryCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'placedAt': placedAt.toIso8601String(),
        'branchName': branchName,
        'fulfillment': fulfillment,
        'status': status.name,
        'itemCount': itemCount,
        'total': total,
        'itemImages': itemImages,
        'reviewProducts': reviewProducts
            .map(
              (product) => <String, dynamic>{
                'name': product.name,
                'description': product.description,
                'image': product.image,
                'price': product.price,
              },
            )
            .toList(growable: false),
        'driverName': driverName,
        'employeeName': employeeName,
        'eta': eta,
        'deliveryAddress': deliveryAddress,
        'deliveryLatitude': deliveryLatitude,
        'deliveryLongitude': deliveryLongitude,
        'deliveryCode': deliveryCode,
      };
}

class CustomerOrdersController extends ChangeNotifier {
  CustomerOrdersController._();

  static final CustomerOrdersController instance = CustomerOrdersController._();
  static const String _storageKey = 'getin_demo_created_orders_v1';

  SharedPreferences? _preferences;
  bool _initialized = false;
  final List<GetinOrder> _createdOrders = <GetinOrder>[];

  List<GetinOrder> get createdOrders => List.unmodifiable(_createdOrders);

  static Future<void> initialize() => instance._initialize();

  Future<void> _initialize() async {
    if (_initialized) return;
    _preferences = await SharedPreferences.getInstance();
    _initialized = true;
    _load();
  }

  void _load() {
    final raw = _preferences?.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _createdOrders
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map(
                (entry) => GetinOrder.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .where((order) =>
                  order.id.isNotEmpty && order.branchName.isNotEmpty),
        );
      notifyListeners();
    } catch (_) {
      _createdOrders.clear();
      unawaited(_preferences?.remove(_storageKey));
    }
  }

  void addCreatedOrder(GetinOrder order) {
    _createdOrders.removeWhere((existing) => existing.id == order.id);
    _createdOrders.insert(0, order);
    notifyListeners();
    unawaited(_persist());
  }

  void clearCreatedOrdersForTesting() {
    _createdOrders.clear();
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) return;

    if (_createdOrders.isEmpty) {
      await preferences.remove(_storageKey);
      return;
    }

    await preferences.setString(
      _storageKey,
      jsonEncode(_createdOrders.map((order) => order.toJson()).toList()),
    );
  }

  @visibleForTesting
  Future<void> reloadFromStorageForTesting() async {
    _preferences ??= await SharedPreferences.getInstance();
    _initialized = true;
    _createdOrders.clear();
    _load();
  }
}

class OrdersScreen extends StatefulWidget {
  final Branch branch;

  const OrdersScreen({
    super.key,
    required this.branch,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const bool _previewLoggedIn = bool.fromEnvironment(
    'GETIN_PREVIEW_LOGGED_IN',
    defaultValue: true,
  );

  OrderFilter _filter = OrderFilter.all;

  late final List<GetinOrder> _orders = [
    GetinOrder(
      id: 'GC-10582',
      placedAt: DateTime(2026, 9, 19, 14, 14),
      branchName: widget.branch.name,
      fulfillment: 'Delivery',
      status: GetinOrderStatus.outForDelivery,
      itemCount: 3,
      total: 'EGP 245',
      itemImages: const [
        'assets/images/products/iced_latte.png',
        'assets/images/products/butter_croissant.png',
        'assets/images/products/blueberry_muffin.png',
      ],
      reviewProducts: const [
        ReviewableProduct(
          name: 'Iced Latte',
          description: 'Double espresso, fresh milk and ice.',
          image: 'assets/images/products/iced_latte.png',
          price: 'EGP 65',
        ),
        ReviewableProduct(
          name: 'Butter Croissant',
          description: 'Buttery, flaky croissant baked fresh.',
          image: 'assets/images/products/butter_croissant.png',
          price: 'EGP 45',
        ),
        ReviewableProduct(
          name: 'Blueberry Muffin',
          description: 'Soft muffin with blueberries.',
          image: 'assets/images/products/blueberry_muffin.png',
          price: 'EGP 60',
        ),
      ],
      driverName: 'Ahmed Hassan',
      eta: '12 min',
      deliveryAddress: 'Stanley, Alexandria',
      // Development sample destination.
      // Production values must come from the customer's saved checkout location.
      deliveryLatitude: 31.2453,
      deliveryLongitude: 29.9668,
      deliveryCode: '4729',
    ),
    GetinOrder(
      id: 'GC-10491',
      placedAt: DateTime(2026, 9, 18, 9, 35),
      branchName: widget.branch.name,
      fulfillment: 'Pickup',
      status: GetinOrderStatus.delivered,
      itemCount: 2,
      total: 'EGP 135',
      itemImages: const [
        'assets/images/products/caramel_macchiato.png',
        'assets/images/products/turkey_cheese_sandwich.png',
      ],
      reviewProducts: const [
        ReviewableProduct(
          name: 'Caramel Macchiato',
          description: 'Espresso, milk and caramel finish.',
          image: 'assets/images/products/caramel_macchiato.png',
          price: 'EGP 70',
        ),
        ReviewableProduct(
          name: 'Turkey & Cheese',
          description: 'Turkey, cheese and fresh greens.',
          image: 'assets/images/products/turkey_cheese_sandwich.png',
          price: 'EGP 95',
        ),
      ],
      employeeName: 'Mariam Adel',
    ),
    GetinOrder(
      id: 'GC-10442',
      placedAt: DateTime(2026, 9, 17, 17, 20),
      branchName: widget.branch.name,
      fulfillment: 'Delivery',
      status: GetinOrderStatus.delivered,
      itemCount: 2,
      total: 'EGP 144.99',
      itemImages: const [
        'assets/images/products/iced_latte.png',
        'assets/images/products/blueberry_muffin.png',
      ],
      reviewProducts: const [
        ReviewableProduct(
          name: 'Iced Latte',
          description: 'Double espresso, fresh milk and ice.',
          image: 'assets/images/products/iced_latte.png',
          price: 'EGP 65',
        ),
        ReviewableProduct(
          name: 'Blueberry Muffin',
          description: 'Soft muffin with blueberries.',
          image: 'assets/images/products/blueberry_muffin.png',
          price: 'EGP 60',
        ),
      ],
      driverName: 'Omar Adel',
      deliveryAddress: 'Stanley, Alexandria',
    ),
    GetinOrder(
      id: 'GC-10376',
      placedAt: DateTime(2026, 9, 16, 18, 8),
      branchName: widget.branch.name,
      fulfillment: 'Delivery',
      status: GetinOrderStatus.cancelled,
      itemCount: 1,
      total: 'EGP 75',
      itemImages: const [
        'assets/images/products/pistachio_latte.png',
      ],
      reviewProducts: const [
        ReviewableProduct(
          name: 'Pistachio Latte',
          description: 'Espresso, milk and pistachio.',
          image: 'assets/images/products/pistachio_latte.png',
          price: 'EGP 75',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    CustomerOrdersController.instance.addListener(_handleOrdersChanged);
  }

  @override
  void dispose() {
    CustomerOrdersController.instance.removeListener(_handleOrdersChanged);
    super.dispose();
  }

  void _handleOrdersChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<GetinOrder> get _allOrders => <GetinOrder>[
        ...CustomerOrdersController.instance.createdOrders,
        ..._orders,
      ];

  List<GetinOrder> get _visibleOrders {
    switch (_filter) {
      case OrderFilter.all:
        return _allOrders;
      case OrderFilter.active:
        return _allOrders.where((order) => order.isActive).toList();
      case OrderFilter.completed:
        return _allOrders
            .where(
              (order) => order.status == GetinOrderStatus.delivered,
            )
            .toList();
      case OrderFilter.cancelled:
        return _allOrders
            .where(
              (order) => order.status == GetinOrderStatus.cancelled,
            )
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_previewLoggedIn) {
      return const _LoggedOutOrders();
    }

    final orders = _visibleOrders;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Orders',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Track active orders and review your order history.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _OrderTabs(
                    selected: _filter,
                    onChanged: (value) {
                      setState(() {
                        _filter = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: orders.isEmpty
                  ? const _EmptyOrdersState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        24,
                      ),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 11),
                      itemBuilder: (context, index) {
                        final order = orders[index];

                        return _OrderCard(
                          order: order,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                  order: order,
                                ),
                              ),
                            );
                          },
                          onRate: order.status == GetinOrderStatus.delivered
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderReviewScreen(
                                        orderId: order.id,
                                        branchName: order.branchName,
                                        fulfillment: order.fulfillment,
                                        products: order.reviewProducts,
                                        driverName:
                                            order.fulfillment == 'Delivery'
                                                ? order.driverName
                                                : null,
                                        employeeName:
                                            order.fulfillment == 'Pickup'
                                                ? order.employeeName
                                                : null,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTabs extends StatelessWidget {
  final OrderFilter selected;
  final ValueChanged<OrderFilter> onChanged;

  const _OrderTabs({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          _OrderTab(
            label: 'All',
            value: OrderFilter.all,
            selected: selected,
            onTap: onChanged,
          ),
          _OrderTab(
            label: 'Active',
            value: OrderFilter.active,
            selected: selected,
            onTap: onChanged,
          ),
          _OrderTab(
            label: 'Completed',
            value: OrderFilter.completed,
            selected: selected,
            onTap: onChanged,
          ),
          _OrderTab(
            label: 'Cancelled',
            value: OrderFilter.cancelled,
            selected: selected,
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

class _OrderTab extends StatelessWidget {
  final String label;
  final OrderFilter value;
  final OrderFilter selected;
  final ValueChanged<OrderFilter> onTap;

  const _OrderTab({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == selected;

    return Expanded(
      child: Material(
        color: active ? AppColors.green : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onTap(value),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.beige : AppColors.green,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final GetinOrder order;
  final VoidCallback onTap;
  final VoidCallback? onRate;

  const _OrderCard({
    required this.order,
    required this.onTap,
    this.onRate,
  });

  bool _fullyReviewed() {
    final store = CustomerReviewStore.instance;
    final productsDone = order.reviewProducts.every(
      (product) => store.hasProductReview(
        orderId: order.id,
        productName: product.name,
      ),
    );
    final driverDone = order.fulfillment != 'Delivery' ||
        order.driverName == null ||
        store.hasDriverReview(order.id);
    final employeeDone = order.fulfillment != 'Pickup' ||
        store.hasServiceReview(orderId: order.id, kind: 'employee');
    final branchDone = order.fulfillment != 'Pickup' ||
        store.hasServiceReview(orderId: order.id, kind: 'branch');
    return productsDone && driverDone && employeeDone && branchDone;
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusText(order.status);
    final active = order.isActive;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  active ? AppColors.green.withOpacity(0.28) : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ORDER #${order.id}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  _StatusPill(
                    text: status,
                    status: order.status,
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderImages(
                    images: order.itemImages,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.branchName,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${order.fulfillment} · ${order.itemCount} items',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.total,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.green,
                  ),
                ],
              ),
              if (order.status == GetinOrderStatus.outForDelivery) ...[
                const SizedBox(height: 11),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.beige.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delivery_dining_rounded,
                        color: AppColors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Driver ${order.driverName ?? ''} · ETA ${order.eta ?? '--'}',
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (onRate != null) ...[
                const SizedBox(height: 11),
                AnimatedBuilder(
                  animation: CustomerReviewStore.instance,
                  builder: (context, _) {
                    final reviewed = _fullyReviewed();
                    return SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: onRate,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: Icon(
                          reviewed
                              ? Icons.check_circle_rounded
                              : Icons.star_rounded,
                          size: 17,
                        ),
                        label: Text(
                          reviewed ? 'View ratings' : 'Rate order',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderImages extends StatelessWidget {
  final List<String> images;

  const _OrderImages({
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    final visible = images.take(3).toList();

    return SizedBox(
      width: 78,
      height: 58,
      child: Stack(
        children: List.generate(
          visible.length,
          (index) {
            return Positioned(
              left: index * 18,
              top: 0,
              child: Container(
                width: 50,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  visible[index],
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final GetinOrderStatus status;

  const _StatusPill({
    required this.text,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == GetinOrderStatus.cancelled;
    final isDelivered = status == GetinOrderStatus.delivered;

    final background = isCancelled
        ? const Color(0xFFFCE8E8)
        : isDelivered
            ? const Color(0xFFE9F3ED)
            : AppColors.beige.withOpacity(0.52);

    final foreground = isCancelled ? const Color(0xFFB84242) : AppColors.green;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LoggedOutOrders extends StatelessWidget {
  const _LoggedOutOrders();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            28,
          ),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Orders',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: AppColors.beige,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.green,
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sign in to view your orders',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track active orders, delivery progress and previous purchases.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SignInScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.beige,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignUpScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.beige,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.green,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders found',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Your Getin orders will appear here.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusText(GetinOrderStatus status) {
  switch (status) {
    case GetinOrderStatus.pending:
      return 'PENDING';
    case GetinOrderStatus.confirmed:
      return 'CONFIRMED';
    case GetinOrderStatus.preparing:
      return 'PREPARING';
    case GetinOrderStatus.ready:
      return 'READY';
    case GetinOrderStatus.outForDelivery:
      return 'OUT FOR DELIVERY';
    case GetinOrderStatus.delivered:
      return 'COMPLETED';
    case GetinOrderStatus.cancelled:
      return 'CANCELLED';
  }
}
