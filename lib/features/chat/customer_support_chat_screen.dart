import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/chat/customer_chat_store.dart';
import '../../core/theme/app_colors.dart';

class CustomerSupportChatScreen extends StatefulWidget {
  const CustomerSupportChatScreen({super.key});

  @override
  State<CustomerSupportChatScreen> createState() =>
      _CustomerSupportChatScreenState();
}

class _CustomerSupportChatScreenState extends State<CustomerSupportChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CustomerChatStore _store = CustomerChatStore.instance;
  bool _sending = false;

  static const List<String> _quickActions = <String>[
    'Where is my order?',
    'Payment problem',
    'Missing item',
    'Rewards issue',
    'Talk to an agent',
  ];

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    unawaited(_seed());
  }

  Future<void> _seed() async {
    await _store.ensureSupportSeeded();
    _scheduleScroll();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
    _scheduleScroll();
  }

  void _scheduleScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? preset]) async {
    if (_sending) return;
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _controller.clear();
    await _store.addMessage(
      threadId: CustomerChatStore.supportThreadId,
      author: CustomerChatAuthor.customer,
      text: text,
    );
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await _store.addMessage(
      threadId: CustomerChatStore.supportThreadId,
      author: CustomerChatAuthor.getin,
      text: _demoReply(text),
    );
    if (mounted) setState(() => _sending = false);
  }

  String _demoReply(String input) {
    final text = input.toLowerCase();
    if (text.contains('where') || text.contains('order')) {
      return 'Your latest demo delivery can be checked from Orders. If you open a specific order, Getin support can attach that order context automatically.';
    }
    if (text.contains('payment') || text.contains('charged')) {
      return 'For a payment problem, open Help & Support → Payment Issue and choose the affected order or saved payment method. The demo request will keep that context.';
    }
    if (text.contains('missing') || text.contains('wrong item')) {
      return 'For a missing or wrong item, choose Help & Support → Order Issue, select the order, then choose Missing item or Wrong item.';
    }
    if (text.contains('reward') ||
        text.contains('star') ||
        text.contains('voucher')) {
      return 'I can help with Stars, rewards and vouchers. In this demo, open Help & Support → Rewards & Membership to attach the exact benefit that has a problem.';
    }
    if (text.contains('agent') || text.contains('human')) {
      return 'A Getin support agent would join this thread in production. For the demo, you can continue typing here or create a structured support request.';
    }
    return 'Thanks — I saved your message in this local demo chat. In production, this thread will be handled by Getin Customer Service and can carry your authenticated account/order context.';
  }

  @override
  Widget build(BuildContext context) {
    final messages = _store.messagesFor(CustomerChatStore.supportThreadId);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat with Getin',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Demo customer service',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.green,
                    child: Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.beige,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Getin Customer Service',
                          style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Local demo chat · messages stay on this device',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _quickActions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final action = _quickActions[index];
                  return ActionChip(
                    label: Text(action),
                    onPressed: _sending ? null : () => _send(action),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    labelStyle: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: messages.length,
                itemBuilder: (context, index) =>
                    _ChatBubble(message: messages[index]),
              ),
            ),
            _ChatComposer(
              controller: _controller,
              sending: _sending,
              hintText: 'Message Getin Support',
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final CustomerChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.author == CustomerChatAuthor.customer;
    final system = message.author == CustomerChatAuthor.system;
    if (system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10.5,
            height: 1.35,
          ),
        ),
      );
    }
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.green : Colors.white,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: mine ? const Radius.circular(5) : null,
            bottomLeft: mine ? null : const Radius.circular(5),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: mine ? Colors.white : AppColors.green,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final String hintText;
  final Future<void> Function([String?]) onSend;

  const _ChatComposer({
    required this.controller,
    required this.sending,
    required this.hintText,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !sending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: AppColors.cream,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : () => onSend(),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.beige,
              ),
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.beige,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
