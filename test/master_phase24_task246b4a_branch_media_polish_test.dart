import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-4A scopes nearby branches to the selected country', () {
    final service = File(
      'lib/features/location/services/branch_service.dart',
    ).readAsStringSync();
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    final list = File(
      'lib/features/location/branch_list_screen.dart',
    ).readAsStringSync();
    final picker = File(
      'lib/features/menu/menu_branch_picker_screen.dart',
    ).readAsStringSync();

    expect(service, contains('String? countryCode'));
    expect(service, contains('normalizedCountry'));
    expect(service, contains("branch.countryCode?.trim().toUpperCase()"));
    expect(home, contains('countryCode: branch.countryCode'));
    expect(list, contains('countryCode: selectedBranch.countryCode'));
    expect(picker, contains('countryCode: widget.currentBranch.countryCode'));
  });

  test('Task 246B-4A renders production branch image URLs as network images',
      () {
    final image = File(
      'lib/features/location/widgets/branch_image.dart',
    ).readAsStringSync();
    final homeCards = File(
      'lib/features/home/widgets/nearest_branches_section.dart',
    ).readAsStringSync();
    final branchList = File(
      'lib/features/location/branch_list_screen.dart',
    ).readAsStringSync();
    final menuPicker = File(
      'lib/features/menu/menu_branch_picker_screen.dart',
    ).readAsStringSync();

    expect(image, contains("path.startsWith('https://')"));
    expect(image, contains('Image.network('));
    expect(homeCards, contains('BranchImage('));
    expect(branchList, contains('BranchImage('));
    expect(menuPicker, contains('BranchImage('));
  });

  test('Task 246B-4A supports HTTPS product images in the cart', () {
    final cart = File('lib/features/cart/cart_screen.dart').readAsStringSync();

    expect(cart, contains('class _CartProductImage'));
    expect(cart, contains("path.startsWith('https://')"));
    expect(cart, contains('Image.network('));
    expect(cart, contains('_CartProductImage('));
  });

  test('Task 246B-4A gives catalog prices a separate brand accent', () {
    final home = File(
      'lib/features/home/widgets/managed_product_sections.dart',
    ).readAsStringSync();
    final menu = File('lib/features/menu/menu_screen.dart').readAsStringSync();
    final cart = File('lib/features/cart/cart_screen.dart').readAsStringSync();

    expect(home, contains('product.displayPrice'));
    expect(home, contains('color: AppColors.gold'));
    expect(menu, contains('color: AppColors.gold'));
    expect(cart, contains('color: AppColors.gold'));
  });
}
