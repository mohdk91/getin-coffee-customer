import 'package:flutter/material.dart';

import '../../core/auth/customer_auth_store.dart';
import '../../core/network/api_exception.dart';
import '../../core/orders/live_order_lifecycle_service.dart';
import '../../core/orders/live_order_models.dart';
import '../../core/theme/app_colors.dart';

class LiveOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const LiveOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<LiveOrderDetailScreen> createState() => _LiveOrderDetailScreenState();
}

class _LiveOrderDetailScreenState extends State<LiveOrderDetailScreen> {
  late final LiveOrderLifecycleService _service;
  LiveOrderDetail? _detail;
  List<LiveOrderTimelineEntry> _deliveryTimeline = const <LiveOrderTimelineEntry>[];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = LiveOrderLifecycleService(CustomerAuthStore.instance.context);
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }
    try {
      final detail = await _service.loadOrder(widget.orderId);
      var deliveryTimeline = const <LiveOrderTimelineEntry>[];
      if (detail.isDelivery) {
        try {
          deliveryTimeline = await _service.loadDeliveryTimeline(widget.orderId);
        } catch (_) {
          deliveryTimeline = const <LiveOrderTimelineEntry>[];
        }
      }
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _deliveryTimeline = deliveryTimeline;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFor(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(detail == null || detail.orderNumber.isEmpty
            ? 'Order'
            : 'Order ${detail.orderNumber}'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh order',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(detail),
    );
  }

  Widget _buildBody(LiveOrderDetail? detail) {
    if (_loading && detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage ?? 'Unable to load this order.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          MediaQuery.viewPaddingOf(context).bottom + 28,
        ),
        children: [
          _LiveOrderStatusCard(detail: detail),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            _OrderNotice(message: _errorMessage!),
          ],
          const SizedBox(height: 14),
          _LiveOrderTimelineCard(
            entries: _deliveryTimeline.isNotEmpty
                ? _deliveryTimeline
                : detail.timeline,
          ),
          const SizedBox(height: 14),
          _LiveOrderItemsCard(detail: detail),
          const SizedBox(height: 14),
          _LiveOrderAddressCard(detail: detail),
          const SizedBox(height: 14),
          _LiveOrderPaymentCard(detail: detail),
        ],
      ),
    );
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'Unable to refresh this order from GETIN right now.';
  }
}

class _LiveOrderStatusCard extends StatelessWidget {
  final LiveOrderDetail detail;

  const _LiveOrderStatusCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIVE ORDER STATUS',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _titleCase(detail.status),
            style: const TextStyle(
              color: AppColors.beige,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${detail.branchName} · ${_titleCase(detail.orderType)}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          if (detail.cancellationReason != null) ...[
            const SizedBox(height: 10),
            Text(
              'Cancellation reason: ${detail.cancellationReason}',
              style: const TextStyle(color: Colors.white, fontSize: 10.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveOrderTimelineCard extends StatelessWidget {
  final List<LiveOrderTimelineEntry> entries;

  const _LiveOrderTimelineCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    return _LiveOrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order timeline',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text(
              'Timeline events will appear as the order progresses.',
              style: TextStyle(color: AppColors.muted, fontSize: 10.5),
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.description?.trim().isNotEmpty == true
                                ? entry.description!
                                : _titleCase(entry.status),
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (entry.eventType != null &&
                              entry.description?.trim().isNotEmpty == true)
                            Text(
                              _titleCase(entry.eventType!),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 9,
                              ),
                            ),
                          if (entry.occurredAt != null)
                            Text(
                              _dateTime(entry.occurredAt!),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 9.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveOrderItemsCard extends StatelessWidget {
  final LiveOrderDetail detail;

  const _LiveOrderItemsCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return _LiveOrderCard(
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
          const SizedBox(height: 10),
          ...detail.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '×${item.quantity}',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.options.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.options.entries
                                .map((entry) => '${entry.key}: ${entry.value}')
                                .join(' · '),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                        if (item.notes != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.notes!,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    _money(detail.currency, item.lineTotal),
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
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

class _LiveOrderAddressCard extends StatelessWidget {
  final LiveOrderDetail detail;

  const _LiveOrderAddressCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final address = detail.deliveryAddress;
    return _LiveOrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.isDelivery ? 'Delivery information' : 'Pickup information',
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            detail.branchName,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (address != null && address.formatted.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              address.formatted,
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ],
          if (address?.recipientName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Recipient: ${address!.recipientName}',
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveOrderPaymentCard extends StatelessWidget {
  final LiveOrderDetail detail;

  const _LiveOrderPaymentCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return _LiveOrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment summary',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _AmountRow(label: 'Subtotal', value: detail.subtotal, detail: detail),
          if (detail.discountTotal > 0)
            _AmountRow(
              label: 'Discount',
              value: -detail.discountTotal,
              detail: detail,
            ),
          if (detail.deliveryFee > 0)
            _AmountRow(
              label: 'Delivery',
              value: detail.deliveryFee,
              detail: detail,
            ),
          if (detail.taxTotal > 0)
            _AmountRow(label: 'Tax', value: detail.taxTotal, detail: detail),
          const Divider(height: 20, color: AppColors.border),
          _AmountRow(
            label: 'Total',
            value: detail.total,
            detail: detail,
            strong: true,
          ),
          const SizedBox(height: 8),
          Text(
            '${_titleCase(detail.paymentMethod)} · ${_titleCase(detail.paymentStatus)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final LiveOrderDetail detail;
  final bool strong;

  const _AmountRow({
    required this.label,
    required this.value,
    required this.detail,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.green,
                fontSize: strong ? 12 : 10.5,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            _money(detail.currency, value),
            style: TextStyle(
              color: value < 0 ? AppColors.gold : AppColors.green,
              fontSize: strong ? 12 : 10.5,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderNotice extends StatelessWidget {
  final String message;

  const _OrderNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.green, fontSize: 10.5),
      ),
    );
  }
}

class _LiveOrderCard extends StatelessWidget {
  final Widget child;

  const _LiveOrderCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

String _titleCase(String value) {
  final clean = value.trim().replaceAll('_', ' ');
  if (clean.isEmpty) return 'Pending';
  return clean
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _money(String currency, double value) {
  final sign = value < 0 ? '- ' : '';
  return '$sign${currency.isEmpty ? 'EGP' : currency} ${value.abs().toStringAsFixed(2)}';
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
