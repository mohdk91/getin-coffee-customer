import 'package:flutter/material.dart';

import '../../core/auth/customer_auth_store.dart';
import '../../core/gift_cards/customer_gift_card_store.dart';
import '../../core/network/api_exception.dart';
import '../../core/orders/live_order_lifecycle_service.dart';
import '../../core/orders/live_order_models.dart';
import '../../core/reviews/customer_review_store.dart';
import '../../core/theme/app_colors.dart';
import '../reviews/review_screens.dart';

class LiveOrderDetailScreen extends StatefulWidget {
  final int orderId;
  final Future<void> Function()? onOrderChanged;

  const LiveOrderDetailScreen({
    super.key,
    required this.orderId,
    this.onOrderChanged,
  });

  @override
  State<LiveOrderDetailScreen> createState() => _LiveOrderDetailScreenState();
}

class _LiveOrderDetailScreenState extends State<LiveOrderDetailScreen> {
  late final LiveOrderLifecycleService _service;
  LiveOrderDetail? _detail;
  List<LiveOrderTimelineEntry> _deliveryTimeline = const <LiveOrderTimelineEntry>[];
  LiveRefundRequest? _refundRequest;
  LiveDeliveryPin? _deliveryPin;
  LiveDeliveryQr? _deliveryQr;
  CustomerOrderReviewStatus? _reviewStatus;
  bool _loading = true;
  bool _actionBusy = false;
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
      CustomerOrderReviewStatus? reviewStatus;
      try {
        reviewStatus = await CustomerReviewStore.instance.loadOrderStatus(
          widget.orderId,
          force: true,
        );
      } catch (_) {
        reviewStatus = null;
      }
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _deliveryTimeline = deliveryTimeline;
        _reviewStatus = reviewStatus;
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

  Future<void> _notifyOrderChanged() async {
    final callback = widget.onOrderChanged;
    if (callback != null) {
      await callback();
    }
  }

  Future<void> _refreshAuthoritativeState() async {
    final detail = await _service.loadOrder(widget.orderId);
    var deliveryTimeline = const <LiveOrderTimelineEntry>[];
    if (detail.isDelivery) {
      try {
        deliveryTimeline = await _service.loadDeliveryTimeline(widget.orderId);
      } catch (_) {
        deliveryTimeline = const <LiveOrderTimelineEntry>[];
      }
    }
    CustomerOrderReviewStatus? reviewStatus;
    try {
      reviewStatus = await CustomerReviewStore.instance.loadOrderStatus(
        widget.orderId,
        force: true,
      );
    } catch (_) {
      reviewStatus = _reviewStatus;
    }
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _deliveryTimeline = deliveryTimeline;
      _reviewStatus = reviewStatus;
    });
  }

  Future<void> _cancelOrder() async {
    final reason = await _requestReason(
      title: 'Cancel order',
      prompt: 'Tell GETIN why you need to cancel this order.',
      actionLabel: 'Cancel order',
      maxLength: 500,
    );
    if (reason == null || !mounted) return;

    setState(() {
      _actionBusy = true;
      _errorMessage = null;
    });
    try {
      await _service.cancelOrder(
        orderId: widget.orderId,
        reason: reason,
      );
      await _refreshAuthoritativeState();
      await CustomerGiftCardStore.instance.refresh();
      await _notifyOrderChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled by GETIN.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFor(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _actionBusy = false;
        });
      }
    }
  }

  Future<void> _issueDeliveryPin() async {
    setState(() {
      _actionBusy = true;
      _errorMessage = null;
    });
    try {
      final pin = await _service.issueDeliveryPin(widget.orderId);
      if (!mounted) return;
      setState(() {
        _deliveryPin = pin;
        _deliveryQr = null;
      });
      await _refreshAuthoritativeState();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFor(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _actionBusy = false;
        });
      }
    }
  }

  Future<void> _issueDeliveryQr() async {
    setState(() {
      _actionBusy = true;
      _errorMessage = null;
    });
    try {
      final qr = await _service.issueDeliveryQr(widget.orderId);
      if (!mounted) return;
      setState(() {
        _deliveryQr = qr;
        _deliveryPin = null;
      });
      await _refreshAuthoritativeState();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFor(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _actionBusy = false;
        });
      }
    }
  }

  Future<void> _requestRefund() async {
    final reason = await _requestReason(
      title: 'Request refund',
      prompt: 'Describe why you are requesting a refund. GETIN calculates the refundable amount on the server.',
      actionLabel: 'Submit refund request',
      maxLength: 1000,
    );
    if (reason == null || !mounted) return;

    setState(() {
      _actionBusy = true;
      _errorMessage = null;
    });
    try {
      final refund = await _service.requestRefund(
        orderId: widget.orderId,
        reason: reason,
      );
      if (!mounted) return;
      setState(() {
        _refundRequest = refund;
      });
      await _refreshAuthoritativeState();
      await _notifyOrderChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund request submitted to GETIN.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFor(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _actionBusy = false;
        });
      }
    }
  }

  Future<void> _openDeliveryReview() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewComposerScreen.driver(
          orderId: widget.orderId.toString(),
          driverName: 'GETIN delivery driver',
        ),
      ),
    );
    await _refreshReviewState();
  }

  Future<void> _openEmployeeReview() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewComposerScreen.employee(
          orderId: widget.orderId.toString(),
          employeeName: 'GETIN pickup employee',
        ),
      ),
    );
    await _refreshReviewState();
  }

  Future<void> _refreshReviewState() async {
    try {
      final status = await CustomerReviewStore.instance.loadOrderStatus(
        widget.orderId,
        force: true,
      );
      await CustomerReviewStore.instance.refreshLiveHistory();
      if (!mounted) return;
      setState(() {
        _reviewStatus = status;
      });
    } catch (_) {
      // Order detail remains usable if the review surface cannot refresh.
    }
  }

  Future<String?> _requestReason({
    required String title,
    required String prompt,
    required String actionLabel,
    required int maxLength,
  }) async {
    final controller = TextEditingController();
    String? validationMessage;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prompt),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: maxLength,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Reason',
                      errorText: validationMessage,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Back'),
                ),
                FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.length < 3) {
                      setDialogState(() {
                        validationMessage = 'Enter at least 3 characters.';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: Text(actionLabel),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    return result;
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
          if (detail.mayOfferCancellation || detail.mayOfferRefund) ...[
            const SizedBox(height: 14),
            _LiveOrderActionsCard(
              busy: _actionBusy,
              onCancel: detail.mayOfferCancellation ? _cancelOrder : null,
              onRefund: detail.mayOfferRefund ? _requestRefund : null,
            ),
          ],
          if (_refundRequest != null) ...[
            const SizedBox(height: 14),
            _RefundRequestCard(refund: _refundRequest!),
          ],
          const SizedBox(height: 14),
          _LiveOrderTimelineCard(
            entries: _deliveryTimeline.isNotEmpty
                ? _deliveryTimeline
                : detail.timeline,
          ),
          if (detail.isDelivery && !detail.isTerminal) ...[
            const SizedBox(height: 14),
            _DeliveryVerificationCard(
              busy: _actionBusy,
              pin: _deliveryPin,
              qr: _deliveryQr,
              onIssuePin: _issueDeliveryPin,
              onIssueQr: _issueDeliveryQr,
            ),
          ],
          if (_reviewStatus != null &&
              (_reviewStatus!.hasEligibleReview ||
                  _reviewStatus!.hasSubmittedReview)) ...[
            const SizedBox(height: 14),
            _LiveOrderReviewCard(
              status: _reviewStatus!,
              busy: _actionBusy,
              onDeliveryReview:
                  _reviewStatus!.delivery.eligible ? _openDeliveryReview : null,
              onEmployeeReview:
                  _reviewStatus!.employee.eligible ? _openEmployeeReview : null,
            ),
          ],
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

class _LiveOrderActionsCard extends StatelessWidget {
  final bool busy;
  final VoidCallback? onCancel;
  final VoidCallback? onRefund;

  const _LiveOrderActionsCard({
    required this.busy,
    required this.onCancel,
    required this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    return _LiveOrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order actions',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'GETIN verifies cancellation eligibility, timing and inventory state on the server.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (onCancel != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: Text(busy ? 'Checking…' : 'Request cancellation'),
              ),
            ),
          if (onCancel != null && onRefund != null)
            const SizedBox(height: 8),
          if (onRefund != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: busy ? null : onRefund,
                icon: const Icon(Icons.currency_exchange_rounded),
                label: Text(busy ? 'Checking…' : 'Request refund'),
              ),
            ),
        ],
      ),
    );
  }
}

class _RefundRequestCard extends StatelessWidget {
  final LiveRefundRequest refund;

  const _RefundRequestCard({required this.refund});

  @override
  Widget build(BuildContext context) {
    return _LiveOrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Refund request',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_titleCase(refund.status)} · ${_money(refund.currency, refund.amount)}',
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'The refundable amount is calculated by GETIN from the paid order and prior successful refunds.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              height: 1.35,
            ),
          ),
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

class _DeliveryVerificationCard extends StatelessWidget {
  final bool busy;
  final LiveDeliveryPin? pin;
  final LiveDeliveryQr? qr;
  final VoidCallback onIssuePin;
  final VoidCallback onIssueQr;

  const _DeliveryVerificationCard({
    required this.busy,
    required this.pin,
    required this.qr,
    required this.onIssuePin,
    required this.onIssueQr,
  });

  @override
  Widget build(BuildContext context) {
    return _LiveOrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery verification',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'PIN and QR credentials are issued by GETIN only after the driver reaches the customer. Requesting early is safely rejected by the server.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              height: 1.35,
            ),
          ),
          if (pin != null) ...[
            const SizedBox(height: 12),
            Center(
              child: SelectableText(
                pin!.pin.split('').join('  '),
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Expires ${pin!.expiresAt == null ? 'soon' : _dateTime(pin!.expiresAt!)} · ${pin!.attemptsRemaining} attempts remaining',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 9),
              ),
            ),
          ],
          if (qr != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Server QR payload',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              qr!.payload,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 9,
                height: 1.3,
              ),
            ),
            if (qr!.expiresAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Expires ${_dateTime(qr!.expiresAt!)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 9),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: busy ? null : onIssuePin,
                  icon: const Icon(Icons.lock_outline_rounded),
                  label: const Text('Issue PIN'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onIssueQr,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('Issue QR'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Share a verification credential only after the order is physically handed to you.',
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

class _LiveOrderReviewCard extends StatelessWidget {
  final CustomerOrderReviewStatus status;
  final bool busy;
  final VoidCallback? onDeliveryReview;
  final VoidCallback? onEmployeeReview;

  const _LiveOrderReviewCard({
    required this.status,
    required this.busy,
    required this.onDeliveryReview,
    required this.onEmployeeReview,
  });

  @override
  Widget build(BuildContext context) {
    final deliverySubmitted = status.delivery.submitted;
    final employeeSubmitted = status.employee.submitted;
    return _LiveOrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate your experience',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Review eligibility comes from GETIN. Production currently supports delivery-driver reviews and pickup-employee reviews.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              height: 1.35,
            ),
          ),
          if (deliverySubmitted || employeeSubmitted) ...[
            const SizedBox(height: 10),
            Text(
              deliverySubmitted
                  ? 'Delivery review submitted.'
                  : 'Pickup employee review submitted.',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (onDeliveryReview != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onDeliveryReview,
                icon: const Icon(Icons.delivery_dining_rounded),
                label: const Text('Rate delivery driver'),
              ),
            ),
          ],
          if (onEmployeeReview != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onEmployeeReview,
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Rate pickup employee'),
              ),
            ),
          ],
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
          if (detail.giftCard != null && detail.giftCard!.applied > 0) ...[
            const SizedBox(height: 4),
            _AmountRow(
              label: detail.giftCard!.lastFour == null
                  ? 'Gift card'
                  : 'Gift card •••• ${detail.giftCard!.lastFour}',
              value: -detail.giftCard!.applied,
              detail: detail,
            ),
            if (detail.giftCard!.refunded > 0)
              _AmountRow(
                label: 'Gift card restored',
                value: detail.giftCard!.refunded,
                detail: detail,
              ),
            _AmountRow(
              label: 'Amount due',
              value: detail.amountDue,
              detail: detail,
              strong: true,
            ),
          ],
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
