import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-7A adds guest quick choice variant and add-on preview', () {
    final screen = File('lib/features/product/live_product_detail_screen.dart')
        .readAsStringSync();
    final preview =
        File('lib/features/product/product_merchandising_preview.dart')
            .readAsStringSync();

    expect(screen, contains('!CustomerAuthStore.instance.isAuthenticated'));
    expect(screen, contains('product.variants.isEmpty'));
    expect(screen, contains('product.optionGroups.isEmpty'));
    expect(screen, contains('GuestProductMerchandisingPreview('));

    expect(preview, contains("title: 'Quick choice'"));
    expect(preview, contains("title: 'Variant'"));
    expect(preview, contains("title: 'Add-ons'"));
    expect(preview, contains("name: 'Most Popular'"));
    expect(preview, contains("_PreviewChoice('Extra Espresso'"));
    expect(preview, contains("_PreviewChoice('Oat Milk'"));
  });

  test('Task 246B-7A builds Often Ordered With from the live branch catalog',
      () {
    final screen = File('lib/features/product/live_product_detail_screen.dart')
        .readAsStringSync();
    final preview =
        File('lib/features/product/product_merchandising_preview.dart')
            .readAsStringSync();

    expect(
      screen,
      contains('productsForBranch(widget.branchId)'),
    );
    expect(screen, contains('candidate.id != product.id'));
    expect(screen, contains('LiveOftenOrderedWith('));
    expect(screen, contains('summary: product'));
    expect(preview, contains("'Often Ordered With'"));
    expect(preview, contains('product.displayPrice'));
    expect(preview, contains('Image.network('));
  });

  test('Task 246B-7A preserves server-authoritative live commerce', () {
    final screen = File('lib/features/product/live_product_detail_screen.dart')
        .readAsStringSync();

    expect(screen, contains('unitPrice: freshQuote.unitTotal'));
    expect(screen, contains('optionValueIds: configuration.optionValueIds'));
    expect(screen, contains('CustomerCatalogStore.instance.quoteProduct'));
    expect(screen, contains('loadAvailability(widget.branchId, product.id)'));
    expect(screen, contains('color: AppColors.gold'));

    // Guest merchandising labels live in their own preview-only widget. The
    // authoritative API screen still contains no hardcoded option payloads.
    expect(screen, isNot(contains("'Vanilla'")));
    expect(screen, isNot(contains("'Oat Milk'")));
    expect(screen, isNot(contains("'+ EGP")));
  });

  test('Task 246B-7A keeps technical fallback copy out of customer UI', () {
    final screen = File('lib/features/product/live_product_detail_screen.dart')
        .readAsStringSync();

    expect(
      screen,
      contains(
        "'Product details are temporarily unavailable. Please try again.'",
      ),
    );
    expect(
      screen,
      isNot(
          contains("'No demo configuration will be substituted in API mode.'")),
    );
  });
}
