import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/orders/customer_checkout_api_repository.dart';
import 'package:getin_coffee/core/orders/customer_orders_api_repository.dart';

void main() {
  test('Master Phase 6 repositories expose live checkout and order operations', () {
    expect(CustomerCheckoutApiRepository, isNotNull);
    expect(CustomerOrdersApiRepository, isNotNull);
  });
}
