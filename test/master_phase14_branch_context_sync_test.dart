import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 14 refreshes catalog/content for the selected branch context', () {
    final shell = File('lib/features/home/home_shell.dart').readAsStringSync();
    final menu = File('lib/features/menu/menu_screen.dart').readAsStringSync();

    expect(shell, contains('CustomerCatalogStore.instance.refreshBranch(_branch.id)'));
    expect(shell, contains('MobileAppContentStore.instance.refresh('));
    expect(shell, contains('unawaited(_syncCommerceContext())'));
    expect(menu, contains('categoriesForBranch(widget.branch.id)'));
    expect(menu, isNot(contains('CustomerCatalogStore.instance.categories.map(')));
  });
}
