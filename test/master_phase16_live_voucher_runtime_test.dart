import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/vouchers/customer_voucher_store.dart';

void main() {
  test('Task 168 keeps vouchers server-backed in API mode', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final repository = File(
      'lib/core/engagement/customer_engagement_api_repository.dart',
    ).readAsStringSync();
    final store = File(
      'lib/core/vouchers/customer_voucher_store.dart',
    ).readAsStringSync();

    expect(
      mainSource,
      contains('CustomerVoucherStore.initialize(CustomerAuthStore.instance.context)'),
    );
    expect(repository, contains("_getItems('/v1/customer/vouchers')"));
    expect(repository, contains("/v1/customer/vouchers/\$voucherId/validate"));
    expect(store, contains('Future<void> refresh() async'));
    expect(store, contains('serverManaged: true'));
  });

  test('Task 168 preserves demo voucher serialization defaults', () {
    final voucher = CustomerVoucher(
      id: 'demo',
      code: 'GETIN20',
      title: 'Demo',
      description: 'Demo voucher',
      discountAmount: 20,
      minimumSpend: 60,
      expiresAt: DateTime(2030),
      terms: 'Demo only',
      status: VoucherStatus.available,
      discountValue: 20,
      currency: 'EGP',
    );

    final restored = CustomerVoucher.fromJson(voucher.toJson());
    expect(restored, isNotNull);
    expect(restored!.code, 'GETIN20');
    expect(restored.serverManaged, isFalse);
  });
}
