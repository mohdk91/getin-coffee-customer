import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/vouchers/customer_voucher_store.dart';
import '../cart/cart_controller.dart';

Future<void> showVoucherPickerSheet(
  BuildContext context, {
  required CartController cart,
}) async {
  final vouchers = CustomerVoucherStore.instance;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return AnimatedBuilder(
        animation: Listenable.merge([cart, vouchers]),
        builder: (context, child) {
          final active = vouchers.vouchers
              .where(
                (voucher) =>
                    voucher.status == VoucherStatus.available ||
                    voucher.status == VoucherStatus.applied,
              )
              .toList(growable: false);
          final eligible =
              active.where(cart.isVoucherApplicable).toList(growable: false);
          if (!vouchers.usesApi) {
            eligible.sort(
              (a, b) => b.discountAmount.compareTo(a.discountAmount),
            );
          }
          final applied = cart.appliedVoucher;

          return SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Use a voucher',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vouchers.usesApi
                                    ? 'Choose a server voucher. Laravel will confirm eligibility and the final saving.'
                                    : 'Choose a saved voucher, or automatically apply the best eligible saving.',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.green,
                        ),
                      ],
                    ),
                  ),
                  if (!vouchers.usesApi && eligible.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _BestVoucherCard(
                        voucher: eligible.first,
                        alreadyApplied: applied?.id == eligible.first.id,
                        onApply: () {
                          if (applied?.id == eligible.first.id) {
                            Navigator.pop(sheetContext);
                            return;
                          }
                          cart.applyVoucher(eligible.first.id);
                          Navigator.pop(sheetContext);
                        },
                      ),
                    ),
                  Flexible(
                    child: active.isEmpty
                        ? const _EmptyVouchers()
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: active.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final voucher = active[index];
                              final isEligible =
                                  cart.isVoucherApplicable(voucher);
                              final selected = applied?.id == voucher.id;

                              return _VoucherOption(
                                voucher: voucher,
                                serverManaged: vouchers.usesApi || voucher.serverManaged,
                                eligible: isEligible,
                                selected: selected,
                                reason: isEligible
                                    ? null
                                    : cart.voucherIneligibilityReason(voucher),
                                onTap: () {
                                  if (selected) {
                                    cart.removeVoucher();
                                    return;
                                  }

                                  if (!isEligible) {
                                    ScaffoldMessenger.of(sheetContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          cart.voucherIneligibilityReason(
                                            voucher,
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  cart.applyVoucher(voucher.id);
                                  Navigator.pop(sheetContext);
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

class _BestVoucherCard extends StatelessWidget {
  final CustomerVoucher voucher;
  final bool alreadyApplied;
  final VoidCallback onApply;

  const _BestVoucherCard({
    required this.voucher,
    required this.alreadyApplied,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.beige,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Best voucher for this cart',
                  style: TextStyle(
                    color: AppColors.beige,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${voucher.code} · Save EGP ${voucher.discountAmount.toStringAsFixed(voucher.discountAmount == voucher.discountAmount.roundToDouble() ? 0 : 2)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onApply,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.beige,
              foregroundColor: AppColors.green,
              minimumSize: const Size(0, 38),
            ),
            child: Text(alreadyApplied ? 'Applied' : 'Auto apply'),
          ),
        ],
      ),
    );
  }
}

class _EmptyVouchers extends StatelessWidget {
  const _EmptyVouchers();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 14, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            color: AppColors.gold,
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            'No saved vouchers available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'You can still enter a voucher code directly in Cart.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherOption extends StatelessWidget {
  final CustomerVoucher voucher;
  final bool serverManaged;
  final bool eligible;
  final bool selected;
  final String? reason;
  final VoidCallback onTap;

  const _VoucherOption({
    required this.voucher,
    required this.serverManaged,
    required this.eligible,
    required this.selected,
    required this.reason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final minimum = voucher.minimumSpend.toStringAsFixed(
      voucher.minimumSpend == voucher.minimumSpend.roundToDouble() ? 0 : 2,
    );
    final discount = voucher.discountAmount.toStringAsFixed(
      voucher.discountAmount == voucher.discountAmount.roundToDouble() ? 0 : 2,
    );
    final serverDetail = voucher.description.trim().isNotEmpty
        ? voucher.description.trim()
        : 'Final saving confirmed by Laravel at checkout.';

    return Material(
      color: selected ? const Color(0xFFF0E8D4) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.confirmation_number_rounded,
                  color: selected ? AppColors.green : AppColors.gold,
                ),
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
                            voucher.title,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          selected
                              ? 'APPLIED'
                              : eligible
                                  ? 'APPLY'
                                  : 'NOT ELIGIBLE',
                          style: TextStyle(
                            color: selected || eligible
                                ? AppColors.green
                                : AppColors.muted,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      serverManaged
                          ? voucher.code
                          : '${voucher.code} · EGP $discount off',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      serverManaged
                          ? serverDetail
                          : 'Minimum spend EGP $minimum',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      eligible
                          ? serverManaged
                              ? 'Laravel will verify this voucher and calculate the final saving.'
                              : 'Eligible for your current cart.'
                          : reason ?? 'Not eligible for this cart.',
                      style: TextStyle(
                        color: eligible ? AppColors.muted : Colors.red.shade400,
                        fontSize: 9.3,
                        height: 1.3,
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
  }
}
