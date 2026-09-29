import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/favorites/customer_favorites_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await CustomerFavoritesStore.instance.resetForTests();
    await CustomerFavoritesStore.initialize();
  });

  FavoriteProductEntry icedLatte() => FavoriteProductEntry.fromProduct(
        name: 'Iced Latte',
        description: 'Double espresso, fresh milk and ice.',
        image: 'assets/images/products/iced_latte.png',
        price: 'EGP 65',
        branchName: 'Getin Stanley',
        serviceType: 'delivery',
      );

  test('product id is stable across product locations', () {
    expect(CustomerFavoritesStore.productId('Iced Latte'), 'iced-latte');
    expect(CustomerFavoritesStore.productId('  Iced   Latte  '), 'iced-latte');
  });

  test('toggle adds and removes a shared favorite', () async {
    final store = CustomerFavoritesStore.instance;
    final product = icedLatte();

    expect(store.containsName(product.name), isFalse);

    final added = await store.toggle(product);
    expect(added, isTrue);
    expect(store.containsName(product.name), isTrue);
    expect(store.count, 1);

    final removed = await store.toggle(product);
    expect(removed, isFalse);
    expect(store.containsName(product.name), isFalse);
    expect(store.count, 0);
  });

  test('remove by id removes the saved product', () async {
    final store = CustomerFavoritesStore.instance;
    final product = icedLatte();

    await store.toggle(product);
    await store.removeById(product.id);

    expect(store.isEmpty, isTrue);
  });
}
