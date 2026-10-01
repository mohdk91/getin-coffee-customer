import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 193 keeps live customer communications server authoritative', () {
    final chatStore = File('lib/core/chat/customer_chat_store.dart').readAsStringSync();
    final support = File('lib/features/chat/customer_support_chat_screen.dart').readAsStringSync();
    final driver = File('lib/features/chat/driver_chat_screen.dart').readAsStringSync();
    final notifications = File('lib/core/notifications/customer_notifications_store.dart').readAsStringSync();
    final notificationScreen = File('lib/features/notifications/notifications_screen.dart').readAsStringSync();
    final repository = File('lib/core/engagement/customer_engagement_api_repository.dart').readAsStringSync();

    expect(repository, contains('/v1/customer/support-conversations'));
    expect(repository, contains('/v1/customer/orders/\$orderId/driver-chat'));
    expect(repository, contains('/v1/customer/conversations/\$conversationId/messages'));
    expect(repository, contains('/v1/customer/conversations/\$conversationId/read'));
    expect(repository, contains('/v1/customer/notifications/unread-count'));

    expect(chatStore, contains('Future<void> refreshThread(String threadId)'));
    expect(chatStore, contains('Future<void> markThreadRead(String threadId)'));
    expect(chatStore, contains('await refreshThread(threadId);'));

    expect(support, contains("_store.usesApi ? 'GETIN customer service'"));
    expect(support, contains("'Live conversation · synced with GETIN'"));
    expect(driver, contains("'Live driver chat · synced with this delivery'"));
    expect(support, contains('RefreshIndicator('));
    expect(driver, contains('RefreshIndicator('));

    expect(notifications, contains('final unreadCount = await repository.notificationUnreadCount();'));
    expect(notificationScreen, contains('item.actionRoute'));
    expect(notificationScreen, contains('navigation.openOrders();'));
  });
}
