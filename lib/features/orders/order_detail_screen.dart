import 'package:flutter/material.dart';

import '../../core/reviews/customer_review_store.dart';
import '../../core/theme/app_colors.dart';
import '../reviews/review_screens.dart';
import '../chat/driver_chat_screen.dart';
import 'orders_screen.dart';
import 'tracking/live_driver_tracking_card.dart';

class OrderDetailScreen extends StatelessWidget {
  final GetinOrder order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Order ${order.id}'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            MediaQuery.viewPaddingOf(context).bottom + 88,
          ),
          children: [
            _OrderSummary(order: order),
            const SizedBox(height: 14),
            _OrderTimeline(status: order.status),
            if (order.status == GetinOrderStatus.outForDelivery) ...[
              const SizedBox(height: 14),
              LiveDriverTrackingCard(
                orderId: order.id,
                destinationLatitude: order.deliveryLatitude,
                destinationLongitude: order.deliveryLongitude,
              ),
              const SizedBox(height: 14),
              _DriverCard(order: order),
              const SizedBox(height: 14),
              DeliveryConfirmationCard(
                code: order.deliveryCode ?? '----',
              ),
            ],
            const SizedBox(height: 14),
            _DeliveryInformation(order: order),
            const SizedBox(height: 14),
            _OrderItems(order: order),
            if (order.status == GetinOrderStatus.delivered) ...[
              const SizedBox(height: 14),
              _ReviewOrderCard(order: order),
            ],
            const SizedBox(height: 14),
            _PaymentSummary(order: order),
          ],
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final GetinOrder order;

  const _OrderSummary({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT STATUS',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _statusTitle(order.status),
            style: const TextStyle(
              color: AppColors.beige,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${order.branchName} · ${order.fulfillment}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          if (order.eta != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.beige,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  'Estimated arrival ${order.eta}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  final GetinOrderStatus status;

  const _OrderTimeline({
    required this.status,
  });

  static const _steps = [
    _TimelineStep(
      label: 'Placed',
      status: GetinOrderStatus.pending,
    ),
    _TimelineStep(
      label: 'Confirmed',
      status: GetinOrderStatus.confirmed,
    ),
    _TimelineStep(
      label: 'Preparing',
      status: GetinOrderStatus.preparing,
    ),
    _TimelineStep(
      label: 'Ready',
      status: GetinOrderStatus.ready,
    ),
    _TimelineStep(
      label: 'Out for delivery',
      status: GetinOrderStatus.outForDelivery,
    ),
    _TimelineStep(
      label: 'Delivered',
      status: GetinOrderStatus.delivered,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (status == GetinOrderStatus.cancelled) {
      return const _SimpleCard(
        child: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: Color(0xFFB84242),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'This order was cancelled.',
                style: TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _statusIndex(status);

    return _SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order progress',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            _steps.length,
            (index) {
              final step = _steps[index];
              final complete = index <= currentIndex;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: complete ? AppColors.green : AppColors.beige,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          complete
                              ? Icons.check_rounded
                              : Icons.circle_outlined,
                          size: 12,
                          color: complete ? AppColors.beige : AppColors.green,
                        ),
                      ),
                      if (index != _steps.length - 1)
                        Container(
                          width: 2,
                          height: 28,
                          color: index < currentIndex
                              ? AppColors.green
                              : AppColors.border,
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      step.label,
                      style: TextStyle(
                        color: complete ? AppColors.green : AppColors.muted,
                        fontSize: 11,
                        fontWeight:
                            complete ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final GetinOrder order;

  const _DriverCard({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.beige,
            child: Icon(
              Icons.delivery_dining_rounded,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your driver',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.driverName ?? 'Driver',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ETA ${order.eta ?? '--'}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton.filledTonal(
                tooltip: 'Call driver',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Demo: calling ${order.driverName ?? 'your driver'} will be enabled with the live delivery provider.',
                      ),
                    ),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.cream,
                  foregroundColor: AppColors.green,
                ),
                icon: const Icon(Icons.phone_outlined),
              ),
              const Text(
                'Call',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Column(
            children: [
              IconButton.filled(
                tooltip: 'Chat with driver',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DriverChatScreen(
                        orderId: order.id,
                        driverName: order.driverName ?? 'Driver',
                        eta: order.eta,
                      ),
                    ),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.beige,
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
              ),
              const Text(
                'Chat',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeliveryConfirmationCard extends StatefulWidget {
  final String code;

  const DeliveryConfirmationCard({
    super.key,
    required this.code,
  });

  @override
  State<DeliveryConfirmationCard> createState() =>
      _DeliveryConfirmationCardState();
}

class _DeliveryConfirmationCardState extends State<DeliveryConfirmationCard> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final displayCode =
        _visible ? widget.code.split('').join('  ') : '•  •  •  •';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: AppColors.gold,
                size: 20,
              ),
              SizedBox(width: 7),
              Text(
                'Delivery Confirmation',
                style: TextStyle(
                  color: AppColors.beige,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Give this one-time code to the driver only after you receive your order.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              displayCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _visible = !_visible;
                });
              },
              icon: Icon(
                _visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
              ),
              label: Text(
                _visible ? 'Hide code' : 'Show delivery code',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.beige,
                side: const BorderSide(
                  color: AppColors.beige,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Never share this code before the order is physically handed to you.',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryInformation extends StatelessWidget {
  final GetinOrder order;

  const _DeliveryInformation({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery information',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 11),
          _InfoRow(
            icon: Icons.storefront_outlined,
            title: 'Branch',
            value: order.branchName,
          ),
          const SizedBox(height: 9),
          _InfoRow(
            icon: order.fulfillment == 'Pickup'
                ? Icons.shopping_bag_outlined
                : Icons.location_on_outlined,
            title: order.fulfillment,
            value: order.fulfillment == 'Pickup'
                ? 'Collect at branch'
                : order.deliveryAddress ?? 'Delivery address',
          ),
        ],
      ),
    );
  }
}

class _OrderItems extends StatelessWidget {
  final GetinOrder order;

  const _OrderItems({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final products = order.reviewProducts;

    return _SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 11),
          if (products.isNotEmpty)
            ...products.asMap().entries.map(
              (entry) {
                final product = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == products.length - 1 ? 0 : 9,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          product.image,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                color: AppColors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.price,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '×1',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            ...order.itemImages.asMap().entries.map(
              (entry) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == order.itemImages.length - 1 ? 0 : 9,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          entry.value,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Getin item ${entry.key + 1}',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Text(
                        '×1',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ReviewOrderCard extends StatelessWidget {
  final GetinOrder order;

  const _ReviewOrderCard({required this.order});

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
    return AnimatedBuilder(
      animation: CustomerReviewStore.instance,
      builder: (context, _) {
        final reviewed = _fullyReviewed();
        return _SimpleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    reviewed ? Icons.check_circle_rounded : Icons.star_rounded,
                    color: reviewed ? AppColors.green : AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reviewed
                          ? 'Thanks for your feedback'
                          : 'How was your order?',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                reviewed
                    ? 'You can reopen your submitted product and driver ratings.'
                    : order.fulfillment == 'Delivery'
                        ? 'Rate each product and rate the delivery driver separately.'
                        : 'Rate each product, the pickup employee/service and this branch.',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderReviewScreen(
                          orderId: order.id,
                          branchName: order.branchName,
                          fulfillment: order.fulfillment,
                          products: order.reviewProducts,
                          driverName: order.fulfillment == 'Delivery'
                              ? order.driverName
                              : null,
                          employeeName: order.fulfillment == 'Pickup'
                              ? order.employeeName
                              : null,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.beige,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    reviewed ? Icons.visibility_outlined : Icons.star_rounded,
                    size: 17,
                  ),
                  label: Text(
                    reviewed ? 'View ratings' : 'Rate Order / Products',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  final GetinOrder order;

  const _PaymentSummary({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Order total',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            order.total,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.green,
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimpleCard extends StatelessWidget {
  final Widget child;

  const _SimpleCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

class _TimelineStep {
  final String label;
  final GetinOrderStatus status;

  const _TimelineStep({
    required this.label,
    required this.status,
  });
}

int _statusIndex(GetinOrderStatus status) {
  switch (status) {
    case GetinOrderStatus.pending:
      return 0;
    case GetinOrderStatus.confirmed:
      return 1;
    case GetinOrderStatus.preparing:
      return 2;
    case GetinOrderStatus.ready:
      return 3;
    case GetinOrderStatus.outForDelivery:
      return 4;
    case GetinOrderStatus.delivered:
      return 5;
    case GetinOrderStatus.cancelled:
      return 0;
  }
}

String _statusTitle(GetinOrderStatus status) {
  switch (status) {
    case GetinOrderStatus.pending:
      return 'Order placed';
    case GetinOrderStatus.confirmed:
      return 'Order confirmed';
    case GetinOrderStatus.preparing:
      return 'Preparing your order';
    case GetinOrderStatus.ready:
      return 'Ready';
    case GetinOrderStatus.outForDelivery:
      return 'Out for delivery';
    case GetinOrderStatus.delivered:
      return 'Delivered';
    case GetinOrderStatus.cancelled:
      return 'Cancelled';
  }
}
