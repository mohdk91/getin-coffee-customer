import 'package:flutter/material.dart';

import '../../core/navigation/app_navigation_controller.dart';
import '../../core/notifications/customer_notifications_store.dart';
import '../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) {
    final value = type.toLowerCase();
    if (value.contains('delivery') || value.contains('order')) {
      return Icons.delivery_dining_rounded;
    }
    if (value.contains('loyal') || value.contains('reward')) {
      return Icons.star_rounded;
    }
    if (value.contains('voucher') || value.contains('coupon')) {
      return Icons.confirmation_number_outlined;
    }
    return Icons.notifications_none_rounded;
  }

  String _timeLabel(DateTime? value) {
    if (value == null) {
      return '';
    }
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  Future<void> _openNotification(
    BuildContext context,
    CustomerNotificationsStore store,
    CustomerNotificationItem item,
  ) async {
    await store.markRead(item.id);
    if (!context.mounted) {
      return;
    }

    final route = (item.actionRoute ?? '').trim().toLowerCase();
    if (route.isEmpty) {
      return;
    }

    final navigation = AppNavigationController.instance;
    if (route.contains('order')) {
      Navigator.of(context).pop();
      navigation.openOrders();
      return;
    }
    if (route.contains('menu') || route.contains('product')) {
      Navigator.of(context).pop();
      navigation.openMenu();
      return;
    }
    if (route.contains('membership') ||
        route.contains('reward') ||
        route.contains('loyalty')) {
      Navigator.of(context).pop();
      navigation.openMembership();
      return;
    }
    if (route.contains('home')) {
      Navigator.of(context).pop();
      navigation.openHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = CustomerNotificationsStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.green,
            elevation: 0,
            title: const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (store.unreadCount > 0)
                TextButton(
                  onPressed: () => store.markAllRead(),
                  child: const Text('Mark all read'),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: RefreshIndicator(
              onRefresh: store.refresh,
              child: store.items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 140),
                        Center(child: Text('No notifications yet.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      itemCount: store.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = store.items[index];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _openNotification(
                              context,
                              store,
                              item,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: !item.isRead
                                      ? AppColors.green
                                      : AppColors.border,
                                  width: !item.isRead ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.cream,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(
                                      _iconFor(item.type),
                                      color: AppColors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: const TextStyle(
                                                  color: AppColors.green,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            if (!item.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.gold,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          item.body,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          _timeLabel(item.createdAt),
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}
