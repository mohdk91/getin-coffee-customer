import 'package:flutter/material.dart';

import '../../core/navigation/app_navigation_controller.dart';
import '../../core/theme/app_colors.dart';
import 'order_detail_screen.dart';
import 'live_order_detail_screen.dart';
import 'orders_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final GetinOrder order;
  final bool delivery;
  final int earnedStars;
  final int earnedStamps;
  final int currentStamps;
  final int freeDrinksUnlocked;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
    required this.delivery,
    required this.earnedStars,
    required this.earnedStamps,
    required this.currentStamps,
    required this.freeDrinksUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final steps = delivery
        ? const [
            'Confirmed',
            'Preparing',
            'Ready',
            'Driver Assigned',
            'On the Way',
            'Delivered',
          ]
        : const [
            'Confirmed',
            'Preparing',
            'Ready for Pickup',
            'Collected',
          ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        AppNavigationController.instance.openHome();
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.beige,
                          size: 46,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        order.status == GetinOrderStatus.pending
                            ? 'Order Placed'
                            : 'Order Confirmed',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        delivery
                            ? 'Good coffee is on the way.'
                            : 'We’ll have your coffee ready for pickup.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _InfoCard(
                        icon: Icons.receipt_long_rounded,
                        title: 'Order #${order.id}',
                        value:
                            '${order.branchName} · ${order.fulfillment} · ${order.eta ?? ''}',
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: _ProgressCard(
                    delivery: delivery,
                    steps: steps,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _InfoCard(
                    icon: delivery
                        ? Icons.location_on_outlined
                        : Icons.storefront_rounded,
                    title: delivery ? 'Delivering to' : 'Pickup from',
                    value: delivery
                        ? (order.deliveryAddress ??
                            'Selected delivery location')
                        : order.branchName,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _InfoCard(
                    icon: Icons.payments_outlined,
                    title: 'Order total',
                    value: order.total,
                  ),
                ),
              ),
              if (earnedStars > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _StarsCard(
                      earnedStars: earnedStars,
                    ),
                  ),
                ),
              if (earnedStamps > 0 || freeDrinksUnlocked > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _StampEarnCard(
                      earnedStamps: earnedStamps,
                      currentStamps: currentStamps,
                      freeDrinksUnlocked: freeDrinksUnlocked,
                    ),
                  ),
                ),
              if (delivery)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _DeliveryCodeCard(
                      code: order.deliveryCode ?? '----',
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => order.apiOrderId != null
                                    ? LiveOrderDetailScreen(
                                        orderId: order.apiOrderId!,
                                        onOrderChanged:
                                            CustomerOrdersController.instance.refreshFromApi,
                                      )
                                    : OrderDetailScreen(order: order),
                              ),
                            );
                          },
                          icon: Icon(
                            delivery
                                ? Icons.delivery_dining_rounded
                                : Icons.shopping_bag_rounded,
                          ),
                          label: Text(
                            delivery ? 'Track My Order' : 'View Order Status',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: AppColors.beige,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            AppNavigationController.instance.openOrders();
                            Navigator.of(context).popUntil(
                              (route) => route.isFirst,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green,
                            side: const BorderSide(
                              color: AppColors.green,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'View All Orders',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {
                          AppNavigationController.instance.openHome();
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          );
                        },
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StampEarnCard extends StatelessWidget {
  final int earnedStamps;
  final int currentStamps;
  final int freeDrinksUnlocked;

  const _StampEarnCard({
    required this.earnedStamps,
    required this.currentStamps,
    required this.freeDrinksUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final title = freeDrinksUnlocked > 0
        ? 'Free drink unlocked!'
        : '+$earnedStamps Getin stamp${earnedStamps == 1 ? '' : 's'}';
    final subtitle = freeDrinksUnlocked > 0
        ? 'Your 7-stamp card completed and a Free Drink reward was added to Rewards.'
        : '$currentStamps / 7 stamps collected · eligible drinks earn 1 stamp each.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.beige.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_cafe_rounded,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final bool delivery;
  final List<String> steps;

  const _ProgressCard({
    required this.delivery,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            delivery ? 'Delivery progress' : 'Pickup progress',
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            steps.length,
            (index) {
              final active = index == 0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: active ? AppColors.green : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active ? AppColors.green : AppColors.border,
                          ),
                        ),
                        child: active
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: AppColors.beige,
                              )
                            : null,
                      ),
                      if (index != steps.length - 1)
                        Container(
                          width: 1,
                          height: 25,
                          color: AppColors.border,
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      steps[index],
                      style: TextStyle(
                        color: active ? AppColors.green : AppColors.muted,
                        fontSize: 10.5,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.green,
            size: 23,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 8.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarsCard extends StatelessWidget {
  final int earnedStars;

  const _StarsCard({
    required this.earnedStars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star_rounded,
            color: AppColors.gold,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You’ll earn $earnedStars Stars from this order.',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCodeCard extends StatelessWidget {
  final String code;

  const _DeliveryCodeCard({
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.gold,
            size: 25,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery confirmation code',
                  style: TextStyle(
                    color: AppColors.beige,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Share it with the driver only when you receive the order.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: code
                      .split('')
                      .map(
                        (digit) => Container(
                          width: 31,
                          height: 38,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.beige,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            digit,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
