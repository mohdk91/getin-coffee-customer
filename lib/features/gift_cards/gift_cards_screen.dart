import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/gift_cards/customer_gift_card_store.dart';
import '../../core/payments/customer_payment_method_store.dart';
import '../../core/theme/app_colors.dart';
import '../payments/payment_methods_screen.dart';

class GiftCardsScreen extends StatefulWidget {
  const GiftCardsScreen({super.key});

  @override
  State<GiftCardsScreen> createState() => _GiftCardsScreenState();
}

class _GiftCardsScreenState extends State<GiftCardsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customAmount = TextEditingController();
  final _recipient = TextEditingController();
  final _contact = TextEditingController();
  final _message = TextEditingController();

  double? _presetAmount = 100;
  DateTime _deliveryDate = DateTime.now();
  bool _sending = false;

  double? get _amount {
    if (_presetAmount != null) {
      return _presetAmount;
    }
    return double.tryParse(_customAmount.text.trim());
  }

  @override
  void dispose() {
    _customAmount.dispose();
    _recipient.dispose();
    _contact.dispose();
    _message.dispose();
    super.dispose();
  }

  String _money(double value) {
    final whole = value == value.roundToDouble();
    return 'EGP ${value.toStringAsFixed(whole ? 0 : 2)}';
  }

  String _date(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    if (value.year == now.year &&
        value.month == now.month &&
        value.day == now.day) {
      return 'Today';
    }
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  Future<void> _chooseDeliveryDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.green,
            onPrimary: AppColors.beige,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() => _deliveryDate = selected);
  }

  Future<void> _chooseCard() async {
    final selected = await showSavedPaymentMethodPicker(context);
    if (!mounted || selected == null) {
      return;
    }
    setState(() {});
  }

  Future<void> _addCard() async {
    final added = await showAddDemoCardSheet(context);
    if (!mounted || added == null) {
      return;
    }
    await CustomerPaymentMethodStore.instance.selectForCheckout(added.id);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _sendGiftCard() async {
    if (!_formKey.currentState!.validate() || _sending) {
      return;
    }
    final amount = _amount;
    if (amount == null || amount < 50 || amount > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose an amount between EGP 50 and EGP 5,000.'),
        ),
      );
      return;
    }

    final payment = CustomerPaymentMethodStore.instance.checkoutMethod;
    if (payment == null || payment.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose an active saved card for this demo purchase.'),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    CustomerGiftCard? card;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      card = await CustomerGiftCardStore.instance.purchase(
        amount: amount,
        recipientName: _recipient.text,
        recipientContact: _contact.text,
        message: _message.text,
        deliveryDate: _deliveryDate,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The gift card could not be created. Try again; no demo purchase was completed.',
          ),
        ),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }

    if (!mounted) {
      return;
    }
    final createdCard = card;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gift card ready'),
        content: Text(
          '${_money(createdCard.amount)} will be sent to ${createdCard.recipientName} on ${_date(createdCard.deliveryDate)}.\n\nDemo gift code: ${createdCard.code}',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    _recipient.clear();
    _contact.clear();
    _message.clear();
    _customAmount.clear();
    setState(() {
      _presetAmount = 100;
      _deliveryDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final giftStore = CustomerGiftCardStore.instance;
    final paymentStore = CustomerPaymentMethodStore.instance;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
        title: const Text(
          'Gift Cards',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([giftStore, paymentStore]),
        builder: (context, _) {
          final selectedCard = paymentStore.checkoutMethod;
          return Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.viewPaddingOf(context).bottom + 36,
              ),
              children: [
                const Text(
                  'Send good coffee',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose an amount and schedule a Getin Gift Card for someone special.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final amount in const <double>[100, 250, 500])
                      _AmountChip(
                        label: _money(amount),
                        selected: _presetAmount == amount,
                        onTap: () {
                          setState(() {
                            _presetAmount = amount;
                            _customAmount.clear();
                          });
                        },
                      ),
                    _AmountChip(
                      label: 'Custom',
                      selected: _presetAmount == null,
                      onTap: () => setState(() => _presetAmount = null),
                    ),
                  ],
                ),
                if (_presetAmount == null) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customAmount,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: _fieldDecoration(
                      label: 'Custom amount',
                      hint: 'EGP 50 – 5,000',
                      icon: Icons.payments_outlined,
                    ),
                    validator: (value) {
                      if (_presetAmount != null) {
                        return null;
                      }
                      final amount = double.tryParse(value?.trim() ?? '');
                      if (amount == null || amount < 50 || amount > 5000) {
                        return 'Enter an amount from EGP 50 to EGP 5,000';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                _SurfaceCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _recipient,
                        textCapitalization: TextCapitalization.words,
                        decoration: _fieldDecoration(
                          label: 'Recipient',
                          hint: 'Name',
                          icon: Icons.person_outline_rounded,
                          borderless: true,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter recipient name'
                                : null,
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      TextFormField(
                        controller: _contact,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _fieldDecoration(
                          label: 'Send to',
                          hint: 'Email or phone',
                          icon: Icons.send_outlined,
                          borderless: true,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter email or phone'
                                : null,
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      TextFormField(
                        controller: _message,
                        minLines: 1,
                        maxLines: 3,
                        decoration: _fieldDecoration(
                          label: 'Message',
                          hint: 'Add a personal note',
                          icon: Icons.chat_bubble_outline_rounded,
                          borderless: true,
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        leading: const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.green,
                        ),
                        title: const Text(
                          'Delivery date',
                          style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(_date(_deliveryDate)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _chooseDeliveryDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SurfaceCard(
                  child: ListTile(
                    leading: const Icon(
                      Icons.credit_card_rounded,
                      color: AppColors.green,
                    ),
                    title: const Text(
                      'Pay by card',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      selectedCard == null
                          ? 'Add or choose a saved card'
                          : '${selectedCard.maskedLabel} · ${selectedCard.expiryLabel}',
                    ),
                    trailing: TextButton(
                      onPressed: selectedCard == null ? _addCard : _chooseCard,
                      child: Text(selectedCard == null ? 'Add' : 'Change'),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _sendGiftCard,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.beige,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.card_giftcard_rounded),
                    label: Text(
                      _sending ? 'Preparing…' : 'Continue',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'My Gift Cards',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                _SurfaceCard(
                  child: ListTile(
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.green,
                      ),
                    ),
                    title: const Text(
                      'Gift Card Balance',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text('${_money(giftStore.balance)} available'),
                    trailing: const Text(
                      'View',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GiftCardWalletScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Gift Card Balance is store credit for eligible Getin purchases. It is separate from cards/cash and is not withdrawable as cash.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class GiftCardWalletScreen extends StatefulWidget {
  const GiftCardWalletScreen({super.key});

  @override
  State<GiftCardWalletScreen> createState() => _GiftCardWalletScreenState();
}

class _GiftCardWalletScreenState extends State<GiftCardWalletScreen> {
  final _codeController = TextEditingController();
  GiftCardStatus? _filter;
  bool _redeeming = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _money(double value) {
    final whole = value == value.roundToDouble();
    return 'EGP ${value.toStringAsFixed(whole ? 0 : 2)}';
  }

  Future<void> _redeem(String code) async {
    if (_redeeming) return;
    final normalized = code.trim();
    if (normalized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a gift card code first.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _redeeming = true);

    GiftCardRedeemResult result;
    try {
      result = await CustomerGiftCardStore.instance.redeemCode(normalized);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not redeem the gift card. Try again.'),
        ),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _redeeming = false);
      }
    }

    if (!mounted) {
      return;
    }
    final message = switch (result) {
      GiftCardRedeemResult.success => 'Gift card added to your balance.',
      GiftCardRedeemResult.invalidCode =>
        'Gift card code is invalid or not redeemable.',
      GiftCardRedeemResult.alreadyRedeemed =>
        'This gift card has already been redeemed.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    if (result == GiftCardRedeemResult.success) {
      _codeController.clear();
      setState(() => _filter = GiftCardStatus.redeemed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = CustomerGiftCardStore.instance;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
        title: const Text(
          'Gift Card Wallet',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final cards = _filter == null
              ? store.cards
              : store.cards.where((card) => card.status == _filter).toList();
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.viewPaddingOf(context).bottom + 36,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.beige,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'GIFT CARD BALANCE',
                          style: TextStyle(
                            color: AppColors.beige,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _money(store.balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Available for eligible Getin Coffee checkout purchases. Not withdrawable as cash.',
                      style: TextStyle(
                        color: Color(0xFFD7CCB0),
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SurfaceCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Redeem a gift card',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter a received Getin Gift Card code. Demo code: GETIN100',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final textScale =
                              MediaQuery.textScalerOf(context).scale(1);
                          final compact =
                              constraints.maxWidth < 340 || textScale > 1.15;

                          final codeField = TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (!_redeeming) {
                                _redeem(_codeController.text);
                              }
                            },
                            decoration: _fieldDecoration(
                              label: 'Gift card code',
                              hint: 'GETIN100',
                              icon: Icons.confirmation_number_outlined,
                            ),
                          );

                          final redeemButton = SizedBox(
                            height: 54,
                            child: FilledButton(
                              onPressed: _redeeming
                                  ? null
                                  : () => _redeem(_codeController.text),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: AppColors.beige,
                              ),
                              child: _redeeming
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.beige,
                                      ),
                                    )
                                  : const Text('Redeem'),
                            ),
                          );

                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                codeField,
                                const SizedBox(height: 8),
                                redeemButton,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: codeField),
                              const SizedBox(width: 8),
                              redeemButton,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Gift Cards',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    _FilterChip(
                      label: 'Sent',
                      selected: _filter == GiftCardStatus.sent,
                      onTap: () =>
                          setState(() => _filter = GiftCardStatus.sent),
                    ),
                    _FilterChip(
                      label: 'Received',
                      selected: _filter == GiftCardStatus.received,
                      onTap: () =>
                          setState(() => _filter = GiftCardStatus.received),
                    ),
                    _FilterChip(
                      label: 'Redeemed',
                      selected: _filter == GiftCardStatus.redeemed,
                      onTap: () =>
                          setState(() => _filter = GiftCardStatus.redeemed),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (cards.isEmpty)
                const _EmptyWalletState()
              else
                for (final card in cards) ...[
                  _GiftCardTile(
                    card: card,
                    onRedeem: card.status == GiftCardStatus.received
                        ? () => _redeem(card.code)
                        : null,
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _GiftCardTile extends StatelessWidget {
  final CustomerGiftCard card;
  final VoidCallback? onRedeem;

  const _GiftCardTile({required this.card, this.onRedeem});

  @override
  Widget build(BuildContext context) {
    final label = switch (card.status) {
      GiftCardStatus.sent => 'SENT',
      GiftCardStatus.received => 'RECEIVED',
      GiftCardStatus.redeemed => 'REDEEMED',
    };
    return _SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${card.currency} ${card.amount.toStringAsFixed(card.amount == card.amount.roundToDouble() ? 0 : 2)}',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: card.status == GiftCardStatus.received
                        ? AppColors.beige
                        : AppColors.cream,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              card.status == GiftCardStatus.sent
                  ? 'To ${card.recipientName} · ${card.recipientContact}'
                  : 'For ${card.recipientName}',
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Code: ${card.code}',
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
            if (card.message.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                '“${card.message}”',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (onRedeem != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRedeem,
                  icon: const Icon(Icons.redeem_rounded),
                  label: const Text('Redeem to Gift Card Balance'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: selected ? AppColors.green : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.beige : AppColors.green,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.green,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? AppColors.beige : AppColors.green,
          fontWeight: FontWeight.w800,
        ),
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _EmptyWalletState extends StatelessWidget {
  const _EmptyWalletState();

  @override
  Widget build(BuildContext context) {
    return const _SurfaceCard(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              color: AppColors.muted,
              size: 38,
            ),
            SizedBox(height: 8),
            Text(
              'No gift cards in this view',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required String hint,
  required IconData icon,
  bool borderless = false,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.green),
    filled: !borderless,
    fillColor: borderless ? null : Colors.white,
    border: borderless ? InputBorder.none : const OutlineInputBorder(),
    enabledBorder: borderless
        ? InputBorder.none
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
    focusedBorder: borderless
        ? InputBorder.none
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.green, width: 1.4),
          ),
  );
}
