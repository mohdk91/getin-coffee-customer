import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/payments/customer_payment_method_store.dart';
import '../../core/payments/demo_card_input.dart';
import '../../core/theme/app_colors.dart';

class PaymentMethodsManagementScreen extends StatelessWidget {
  const PaymentMethodsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CustomerPaymentMethodStore.instance;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
        title: const Text(
          'Payment Methods',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              for (final method in store.methods) ...[
                _PaymentMethodCard(
                  method: method,
                  onTap: () => _managePaymentMethod(context, method),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: () async {
                    await showAddDemoCardSheet(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.beige,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.add_card_rounded),
                  label: const Text(
                    'Add New Card',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const _SecurityNote(),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _managePaymentMethod(
  BuildContext context,
  CustomerPaymentMethod method,
) async {
  final store = CustomerPaymentMethodStore.instance;
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  method.maskedLabel,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method.isExpired
                      ? 'Expired ${method.expiryLabel}'
                      : 'Expires ${method.expiryLabel}',
                  style: TextStyle(
                    color: method.isExpired
                        ? const Color(0xFFB94A48)
                        : AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                if (!method.isExpired && !method.isDefault)
                  _SheetAction(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Set as default',
                    subtitle: 'Use this card first at checkout',
                    onTap: () async {
                      await store.setDefault(method.id);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                  ),
                if (!method.isExpired)
                  _SheetAction(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Use for checkout',
                    subtitle: 'Select this saved payment token',
                    onTap: () async {
                      await store.selectForCheckout(method.id);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                  ),
                _SheetAction(
                  icon: Icons.delete_outline_rounded,
                  title: 'Remove card',
                  subtitle: 'Delete this saved payment reference',
                  danger: true,
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: sheetContext,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Remove card?'),
                        content: Text(
                          '${method.maskedLabel} will be removed from this local demo.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFB94A48),
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !sheetContext.mounted) {
                      return;
                    }
                    await store.remove(method.id);
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<CustomerPaymentMethod?> showAddDemoCardSheet(
  BuildContext context,
) async {
  return showModalBottomSheet<CustomerPaymentMethod>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _AddDemoCardSheet(),
  );
}

Future<CustomerPaymentMethod?> showSavedPaymentMethodPicker(
  BuildContext context,
) async {
  final store = CustomerPaymentMethodStore.instance;
  return showModalBottomSheet<CustomerPaymentMethod>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
            ),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose a saved card',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: store.methods.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final method = store.methods[index];
                        final selected = store.checkoutMethod?.id == method.id;
                        return _PaymentMethodCard(
                          method: method,
                          selected: selected,
                          disabled: method.isExpired,
                          onTap: method.isExpired
                              ? null
                              : () async {
                                  await store.selectForCheckout(method.id);
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext, method);
                                  }
                                },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _AddDemoCardSheet extends StatefulWidget {
  const _AddDemoCardSheet();

  @override
  State<_AddDemoCardSheet> createState() => _AddDemoCardSheetState();
}

class _AddDemoCardSheetState extends State<_AddDemoCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController(text: '12/30');
  final _cvv = TextEditingController();
  String _brand = 'CARD';
  bool _makeDefault = false;
  bool _saving = false;

  @override
  void dispose() {
    _cardNumber.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  void _onCardNumberChanged(String value) {
    final detected = DemoCardInput.detectBrand(value);
    if (detected != _brand) {
      setState(() => _brand = detected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) {
      return;
    }

    final fullNumber = DemoCardInput.digitsOnly(_cardNumber.text);
    final brand = DemoCardInput.detectBrand(fullNumber);
    final parts = _expiry.text.trim().split('/');
    final month = int.parse(parts[0]);
    final twoDigitYear = int.parse(parts[1]);
    final year = 2000 + twoDigitYear;

    setState(() => _saving = true);
    try {
      // The full number and CVV are intentionally never passed to the store.
      // Only masked/token-style demo metadata is persisted locally.
      final method =
          await CustomerPaymentMethodStore.instance.addDemoTokenizedCard(
        brand: brand,
        last4: DemoCardInput.last4(fullNumber),
        expiryMonth: month,
        expiryYear: year,
        makeDefault: _makeDefault,
      );

      _cardNumber.clear();
      _cvv.clear();
      if (!mounted) {
        return;
      }
      Navigator.pop(context, method);
    } on ArgumentError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message?.toString() ?? 'Invalid card')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final systemBottom = MediaQuery.viewPaddingOf(context).bottom;
    final detectedBrand = _brand;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          keyboard + (systemBottom > 16 ? systemBottom : 20) + 12,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Add a card',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Demo only. Use a fake/test card number. The full card number and CVV exist only while this form is open and are never saved. Only a simulated token, brand, last 4 digits and expiry are stored locally.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _CardBrandMark(brand: detectedBrand, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detectedBrand == 'CARD'
                                ? 'Card type will be detected automatically'
                                : detectedBrand,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Visa and Mastercard are supported in this demo.',
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
              const SizedBox(height: 14),
              TextFormField(
                controller: _cardNumber,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.creditCardNumber],
                onChanged: _onCardNumberChanged,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                  const _CardNumberFormatter(),
                ],
                decoration: _inputDecoration(
                  label: 'Card number',
                  hint: '0000 0000 0000 0000',
                  prefix: _CardBrandMark(brand: detectedBrand, size: 30),
                ),
                validator: (value) {
                  final number = DemoCardInput.digitsOnly(value ?? '');
                  final brand = DemoCardInput.detectBrand(number);
                  if (brand == 'CARD') {
                    return 'Enter a supported Visa or Mastercard number';
                  }
                  if (!DemoCardInput.hasValidLength(number, brand)) {
                    return 'Card number length is invalid';
                  }
                  if (!DemoCardInput.passesLuhn(number)) {
                    return 'Enter a valid fake/test card number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiry,
                      keyboardType: TextInputType.number,
                      autofillHints: const [
                        AutofillHints.creditCardExpirationDate
                      ],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                        LengthLimitingTextInputFormatter(5),
                        const _ExpiryFormatter(),
                      ],
                      decoration: _inputDecoration(
                        label: 'Expiry',
                        hint: 'MM/YY',
                        icon: Icons.event_outlined,
                      ),
                      validator: (value) {
                        final match = RegExp(r'^(0[1-9]|1[0-2])/(\d{2})$')
                            .firstMatch(value?.trim() ?? '');
                        if (match == null) {
                          return 'Use MM/YY';
                        }
                        final month = int.parse(match.group(1)!);
                        final year = 2000 + int.parse(match.group(2)!);
                        final preview = CustomerPaymentMethod(
                          id: 'preview',
                          providerTokenRef: 'preview',
                          brand: detectedBrand,
                          last4: '0000',
                          expiryMonth: month,
                          expiryYear: year,
                          isDefault: false,
                        );
                        if (preview.isExpired) {
                          return 'Card is expired';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cvv,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      autofillHints: const [
                        AutofillHints.creditCardSecurityCode
                      ],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: _inputDecoration(
                        label: 'CVV',
                        hint: '•••',
                        icon: Icons.lock_outline_rounded,
                      ),
                      validator: (value) {
                        if (!RegExp(r'^\d{3}$').hasMatch(value?.trim() ?? '')) {
                          return 'Enter 3 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.green,
                title: const Text(
                  'Set as default',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: const Text(
                  'Use this card first at checkout',
                  style: TextStyle(color: AppColors.muted),
                ),
                value: _makeDefault,
                onChanged: (value) => setState(() => _makeDefault = value),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.beige,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_card_rounded),
                  label: Text(
                    _saving ? 'Saving…' : 'Add Demo Card',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    IconData? icon,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
          prefix ?? (icon == null ? null : Icon(icon, color: AppColors.green)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.green, width: 1.5),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  const _CardNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && index % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[index]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  const _ExpiryFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 4 ? digits.substring(0, 4) : digits;
    final formatted = clipped.length <= 2
        ? clipped
        : '${clipped.substring(0, 2)}/${clipped.substring(2)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final CustomerPaymentMethod method;
  final VoidCallback? onTap;
  final bool selected;
  final bool disabled;

  const _PaymentMethodCard({
    required this.method,
    required this.onTap,
    this.selected = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final expired = method.isExpired;
    return Material(
      color: disabled ? Colors.white.withOpacity(0.58) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Opacity(
                  opacity: expired ? 0.45 : 1,
                  child: _CardBrandMark(
                    brand: method.normalizedBrand,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            method.maskedLabel,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  expired ? AppColors.muted : AppColors.green,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (method.isDefault) ...[
                          const SizedBox(width: 7),
                          const _StatusPill(
                            label: 'DEFAULT',
                            background: AppColors.green,
                            foreground: AppColors.beige,
                          ),
                        ],
                        if (expired) ...[
                          const SizedBox(width: 7),
                          const _StatusPill(
                            label: 'EXPIRED',
                            background: Color(0xFFFBE5E3),
                            foreground: Color(0xFF9E3C3A),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expired
                          ? 'Expired ${method.expiryLabel} · cannot be used'
                          : 'Expires ${method.expiryLabel}',
                      style: TextStyle(
                        color:
                            expired ? const Color(0xFF9E3C3A) : AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.radio_button_checked_rounded,
                  color: AppColors.green,
                )
              else if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBrandMark extends StatelessWidget {
  final String brand;
  final double size;

  const _CardBrandMark({
    required this.brand,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = brand.trim().toUpperCase();
    if (normalized == 'VISA') {
      return SizedBox(
        width: size,
        height: size * 0.62,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'VISA',
              style: TextStyle(
                color: const Color(0xFF17357A),
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ),
      );
    }

    if (normalized == 'MASTERCARD') {
      // Keep the two Mastercard circles visibly overlapping. The previous
      // implementation positioned them edge-to-edge, which made the mark look
      // like two unrelated dots on smaller Android screens.
      final circle = size * 0.48;
      return SizedBox(
        width: size,
        height: size * 0.68,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: size * 0.12,
              child: Container(
                width: circle,
                height: circle,
                decoration: const BoxDecoration(
                  color: Color(0xFFEB001B),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: size * 0.12,
              child: Container(
                width: circle,
                height: circle,
                decoration: const BoxDecoration(
                  color: Color(0xFFF79E1B),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        Icons.credit_card_rounded,
        size: size * 0.62,
        color: AppColors.green,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB94A48) : AppColors.green;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: color),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.green, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Demo only: full card number and CVV may be entered to test the UI, but they are never persisted. Getin stores only a simulated provider token reference plus masked card metadata. A production build should use the configured PCI-compliant payment provider.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
