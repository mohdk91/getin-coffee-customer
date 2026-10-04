import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-3 home categories follow the selected branch catalog', () {
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    final categories = File(
      'lib/features/home/widgets/menu_categories_section.dart',
    ).readAsStringSync();

    expect(home, contains('MenuCategoriesSection('));
    expect(home, contains('branchId: branch.id'));
    expect(
        categories, contains('final store = CustomerCatalogStore.instance;'));
    expect(categories, contains('store.categoriesForBranch(branchId)'));
    expect(categories, contains('if (store.usesApi)'));
    expect(categories, contains('if (store.loading)'));
    expect(categories, contains('return const SizedBox.shrink();'));
    expect(categories, contains('networkImage: true'));
    expect(categories, contains('final items = HomeMockData.categories'));
    expect(categories, contains('networkImage: false'));
  });

  test(
      'Task 246B-3 keeps startup repositories centralized in CustomerAppBootstrap',
      () {
    final main = File('lib/main.dart').readAsStringSync();
    final bootstrap = File(
      'lib/core/bootstrap/customer_app_bootstrap.dart',
    ).readAsStringSync();

    expect(main, contains('CustomerAppBootstrap.instance.start(config)'));
    expect(bootstrap, contains('CustomerCatalogStore.initialize(context)'));
    expect(
        bootstrap, contains('CustomerNotificationsStore.initialize(context)'));
    expect(bootstrap, contains('CustomerOrdersController.initialize(context)'));
    expect(bootstrap, contains('CustomerVoucherStore.initialize(context)'));
    expect(
        bootstrap, contains('CustomerPaymentMethodStore.initialize(context)'));
    expect(
        bootstrap, contains('CustomerAccountSync.refreshAfterAuthentication'));
  });
}
