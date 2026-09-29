import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_DemoNotification> _items = <_DemoNotification>[
    _DemoNotification(
      title: 'Your order is on the way',
      body:
          'Order GC-10582 is out for delivery. Ahmed Hassan is heading to you.',
      time: '2 min ago',
      icon: Icons.delivery_dining_rounded,
      unread: true,
    ),
    _DemoNotification(
      title: 'You earned 12 Stars',
      body:
          'Stars from your latest eligible order were added to Getin Rewards.',
      time: 'Today',
      icon: Icons.star_rounded,
      unread: true,
    ),
    _DemoNotification(
      title: 'Voucher expiring soon',
      body: 'GETIN20 expires soon. Open your vouchers to check eligibility.',
      time: 'Yesterday',
      icon: Icons.confirmation_number_outlined,
      unread: false,
    ),
    _DemoNotification(
      title: 'Member benefit',
      body: 'Getin Membership includes member pricing and recurring perks.',
      time: '2 days ago',
      icon: Icons.workspace_premium_outlined,
      unread: false,
    ),
  ];

  int get _unreadCount => _items.where((item) => item.unread).length;

  void _markAllRead() {
    setState(() {
      for (final item in _items) {
        item.unread = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _items[index];
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => item.unread = false),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: item.unread ? AppColors.green : AppColors.border,
                      width: item.unread ? 1.5 : 1,
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
                        child: Icon(item.icon, color: AppColors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                if (item.unread)
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
                              item.time,
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
    );
  }
}

class _DemoNotification {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  bool unread;

  _DemoNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.unread,
  });
}
