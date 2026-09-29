import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/vouchers/customer_voucher_store.dart';
import 'package:getin_coffee/features/cart/cart_controller.dart';

void main() {
  final vouchers = CustomerVoucherStore.instance;
  final cart = CartController.instance;

  CartItem drink({double price = 75}) {
    return CartItem(
      name: 'Iced Latte',
      description: 'Test drink',
      image: 'assets/images/products/iced_latte.png',
      branchName: 'Getin Stanley',
      serviceType: 'delivery',
      currency: 'EGP',
      basePrice: price,
      unitPrice: price,
      quantity: 1,
      size: 'Large',
      temperature: 'Iced',
      milk: 'Full Fat',
      strength: 'Regular',
      sweetness: 'Regular',
      addOns: const [],
    );
  }

  setUp(() {
    cart.clear();
    vouchers.resetToDemoDefaults();
  });

  test('demo vouchers include available, used and expired states', () {
    expect(vouchers.availableVouchers.length, 2);
    expect(vouchers.usedVouchers.length, 1);
    expect(vouchers.expiredVouchers.length, 1);
  });

  test('GETIN20 applies when minimum spend is met', () {
    cart.addOrMerge(drink());

    final result = cart.applyVoucherByCode('GETIN20');

    expect(result, VoucherApplyResult.success);
    expect(cart.voucherDiscount, 20);
    expect(cart.appliedVoucher?.code, 'GETIN20');
    expect(cart.appliedVoucher?.status, VoucherStatus.applied);
  });

  test('GETIN50 rejects cart below minimum spend', () {
    cart.addOrMerge(drink());

    final result = cart.applyVoucherByCode('GETIN50');

    expect(result, VoucherApplyResult.minimumSpendNotMet);
    expect(cart.voucherDiscount, 0);
    expect(cart.appliedVoucher, isNull);
  });

  test('expired and used voucher codes cannot be applied', () {
    cart.addOrMerge(drink(price: 100));

    expect(
      cart.applyVoucherByCode('FALL15'),
      VoucherApplyResult.expired,
    );
    expect(
      cart.applyVoucherByCode('WELCOME10'),
      VoucherApplyResult.used,
    );
  });

  test('removing a voucher returns it to available state', () {
    cart.addOrMerge(drink());
    expect(cart.applyVoucherByCode('GETIN20'), VoucherApplyResult.success);

    final id = cart.appliedVoucher!.id;
    cart.removeVoucher();

    expect(cart.appliedVoucher, isNull);
    expect(vouchers.voucherById(id)?.status, VoucherStatus.available);
  });

  test('successful demo order marks applied voucher used', () {
    cart.addOrMerge(drink());
    expect(cart.applyVoucherByCode('GETIN20'), VoucherApplyResult.success);

    final id = cart.appliedVoucher!.id;
    cart.completeDemoOrder();

    expect(cart.isEmpty, isTrue);
    expect(vouchers.voucherById(id)?.status, VoucherStatus.used);
  });
}
