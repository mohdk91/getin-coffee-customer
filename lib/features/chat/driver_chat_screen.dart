import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/chat/customer_chat_store.dart';
import '../../core/theme/app_colors.dart';

class DriverChatScreen extends StatefulWidget {
  final String orderId;
  final String driverName;
  final String? eta;

  const DriverChatScreen({
    super.key,
    required this.orderId,
    required this.driverName,
    this.eta,
  });

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CustomerChatStore _store = CustomerChatStore.instance;
  bool _sending = false;

  static const List<String> _quickReplies = <String>[
    'Please call when you arrive',
    'Leave at reception',
    'I’m coming down now',
    'Where are you?',
  ];

  String get _threadId => _store.driverThreadId(widget.orderId);

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    unawaited(_seed());
  }

  Future<void> _seed() async {
    await _store.ensureDriverSeeded(
      orderId: widget.orderId,
      driverName: widget.driverName,
    );
    if (_store.usesApi) {
      await _store.markThreadRead(_threadId);
    }
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

  Future<void> _refreshLiveThread() async {
    if (!_store.usesApi) {
      return;
    }
    await _store.refreshThread(_threadId);
    await _store.markThreadRead(_threadId);
  }

  Future<void> _send([String? preset]) async {
    if (_sending) return;
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _controller.clear();
    await _store.addMessage(
      threadId: _threadId,
      author: CustomerChatAuthor.customer,
      text: text,
    );
    if (_store.usesApi) {
      await _store.markThreadRead(_threadId);
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _store.addMessage(
        threadId: _threadId,
        author: CustomerChatAuthor.driver,
        text: _driverReply(text),
      );
    }
    if (mounted) setState(() => _sending = false);
  }

  String _driverReply(String input) {
    final text = input.toLowerCase();
    if (text.contains('call')) {
      return 'Of course. I’ll call when I arrive.';
    }
    if (text.contains('reception')) {
      return 'Got it. I’ll meet reception and follow the delivery confirmation step.';
    }
    if (text.contains('coming down')) {
      return 'Perfect, I’m almost there.';
    }
    if (text.contains('where')) {
      return 'I’m on the way now. Open your order tracking card to view the current delivery location.';
    }
    return 'Got it. See you shortly.';
  }

  @override
  Widget build(BuildContext context) {
    final messages = _store.messagesFor(_threadId);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.driverName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Order ${widget.orderId}${widget.eta == null ? '' : ' · ETA ${widget.eta}'}',
              style: const TextStyle(
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
                color: AppColors.green,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.beige,
                    child: Icon(
                      Icons.delivery_dining_rounded,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.driverName,
                          style: const TextStyle(
                            color: AppColors.beige,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _store.usesApi
                              ? 'Live driver chat · GPS remains server-authoritative in Order Details'
                              : 'Demo driver chat · available during delivery',
                          style: const TextStyle(
                            color: Colors.white70,
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
                itemCount: _quickReplies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final action = _quickReplies[index];
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
              child: RefreshIndicator(
                onRefresh: _refreshLiveThread,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final mine = message.author == CustomerChatAuthor.customer;
                  if (message.author == CustomerChatAuthor.system) {
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
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * .78,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: mine ? AppColors.green : Colors.white,
                        borderRadius: BorderRadius.circular(18).copyWith(
                          bottomRight: mine ? const Radius.circular(5) : null,
                          bottomLeft: mine ? null : const Radius.circular(5),
                        ),
                        border:
                            mine ? null : Border.all(color: AppColors.border),
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
                  },
                ),
              ),
            ),
            SafeArea(
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
                        controller: _controller,
                        enabled: !_sending,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Message ${widget.driverName}',
                          filled: true,
                          fillColor: AppColors.cream,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : () => _send(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.beige,
                      ),
                      icon: _sending
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
            ),
          ],
        ),
      ),
    );
  }
}
