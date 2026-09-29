import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/chat/customer_chat_store.dart';

void main() {
  test('chat message round trips through json', () {
    final original = CustomerChatMessage(
      id: 'm1',
      threadId: 'driver:GC-10582',
      author: CustomerChatAuthor.driver,
      text: 'I am on the way.',
      sentAt: DateTime.utc(2026, 9, 24, 12, 0),
    );

    final restored = CustomerChatMessage.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.threadId, original.threadId);
    expect(restored.author, CustomerChatAuthor.driver);
    expect(restored.text, original.text);
    expect(restored.sentAt, original.sentAt);
  });

  test('unknown chat author safely becomes system', () {
    final restored = CustomerChatMessage.fromJson(<String, dynamic>{
      'id': 'm2',
      'threadId': 'support:getin',
      'author': 'unknown',
      'text': 'System message',
      'sentAt': '2026-09-24T12:00:00.000Z',
    });

    expect(restored.author, CustomerChatAuthor.system);
  });
}
