enum ProductType {
  drink,
  food,
  bakery,
  refreshment,
  merchandise,
}

extension ProductTypeX on ProductType {
  String get label {
    switch (this) {
      case ProductType.drink:
        return 'Drink';
      case ProductType.food:
        return 'Food';
      case ProductType.bakery:
        return 'Bakery';
      case ProductType.refreshment:
        return 'Refreshment';
      case ProductType.merchandise:
        return 'Merchandise';
    }
  }

  bool get isBeverage =>
      this == ProductType.drink || this == ProductType.refreshment;
}

class GetinProductDefinition {
  final ProductType type;
  final String? badge;
  final String stockLabel;

  const GetinProductDefinition({
    required this.type,
    this.badge,
    this.stockLabel = '',
  });
}

class GetinProductCatalog {
  const GetinProductCatalog._();

  static ProductType typeFromCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'food':
        return ProductType.food;
      case 'bakery':
        return ProductType.bakery;
      case 'refreshments':
      case 'refreshment':
        return ProductType.refreshment;
      case 'merchandise':
        return ProductType.merchandise;
      case 'coffee':
      case 'non-coffee':
      default:
        return ProductType.drink;
    }
  }

  static GetinProductDefinition definitionFor(
    String name, {
    ProductType? explicitType,
    String? badge,
  }) {
    final normalized = name.trim().toLowerCase();
    final type = explicitType ?? _typeFromName(normalized);

    String? resolvedBadge = badge;
    if (resolvedBadge == null) {
      if (normalized == 'iced latte') {
        resolvedBadge = 'BEST SELLER';
      } else if (normalized == 'pistachio latte' ||
          normalized == 'pistachio dream latte') {
        resolvedBadge = 'NEW';
      } else if (normalized == 'berry hibiscus' ||
          normalized == 'berry hibiscus refresher') {
        resolvedBadge = 'LIMITED';
      } else if (normalized == 'maple croissant') {
        resolvedBadge = 'SEASONAL';
      }
    }

    return GetinProductDefinition(
      type: type,
      badge: resolvedBadge,
      stockLabel:
          type == ProductType.merchandise ? '12 in stock at this branch' : '',
    );
  }

  static ProductType _typeFromName(String name) {
    if (name.contains('tumbler') ||
        name.contains('mug') ||
        name.contains('bottle') ||
        name.contains('merch')) {
      return ProductType.merchandise;
    }

    if (name.contains('croissant') ||
        name.contains('muffin') ||
        name.contains('cookie') ||
        name.contains('cake')) {
      return ProductType.bakery;
    }

    if (name.contains('sandwich') ||
        name.contains('turkey & cheese') ||
        name.contains('wrap') ||
        name.contains('salad')) {
      return ProductType.food;
    }

    if (name.contains('hibiscus') ||
        name.contains('refresher') ||
        name.contains('lemonade') ||
        name.contains('juice')) {
      return ProductType.refreshment;
    }

    return ProductType.drink;
  }
}
