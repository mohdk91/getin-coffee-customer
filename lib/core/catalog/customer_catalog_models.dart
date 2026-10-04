import '../../features/location/models/branch.dart';

double _catalogDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

class CatalogCategory {
  final int id;
  final String name;
  final String? nameAr;
  final String? imageUrl;
  final int? productCount;

  const CatalogCategory({
    required this.id,
    required this.name,
    this.nameAr,
    this.imageUrl,
    this.productCount,
  });

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      nameAr: json['name_ar']?.toString(),
      imageUrl: json['image_url']?.toString(),
      productCount: (json['product_count'] as num?)?.toInt(),
    );
  }
}

class CatalogProduct {
  final int id;
  final String name;
  final String shortDescription;
  final String? description;
  final String? ingredients;
  final String? allergens;
  final String? imageUrl;
  final String productType;
  final bool isFeatured;
  final double price;
  final String currency;
  final int? preparationTimeMinutes;
  final int? calories;
  final int? categoryId;
  final String? categoryName;
  final List<String> gallery;
  final List<CatalogGalleryImage> galleryItems;
  final List<CatalogVariant> variants;
  final List<CatalogOptionGroup> optionGroups;

  const CatalogProduct({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.productType,
    required this.isFeatured,
    required this.price,
    required this.currency,
    this.description,
    this.ingredients,
    this.allergens,
    this.imageUrl,
    this.preparationTimeMinutes,
    this.calories,
    this.categoryId,
    this.categoryName,
    this.gallery = const <String>[],
    this.galleryItems = const <CatalogGalleryImage>[],
    this.variants = const <CatalogVariant>[],
    this.optionGroups = const <CatalogOptionGroup>[],
  });

  bool get isVariable => productType.trim().toLowerCase() == 'variable';

  String get displayPrice => money(price);

  String money(double value) {
    final normalized = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$currency $normalized';
  }

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    final category = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : const <String, dynamic>{};
    final galleryItems = (json['gallery'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) => CatalogGalleryImage.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((item) => item.url.isNotEmpty)
        .toList(growable: false);
    final variants = (json['variants'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => CatalogVariant.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final optionGroups = (json['option_groups'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) => CatalogOptionGroup.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);

    return CatalogProduct(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '',
      description: json['description']?.toString(),
      ingredients: json['ingredients']?.toString(),
      allergens: json['allergens']?.toString(),
      imageUrl: json['image_url']?.toString(),
      productType: json['product_type']?.toString() ?? '',
      isFeatured: json['is_featured'] == true,
      price: _catalogDouble(json['catalog_price']),
      currency: json['currency']?.toString() ?? 'EGP',
      preparationTimeMinutes:
          (json['preparation_time_minutes'] as num?)?.toInt(),
      calories: (json['calories'] as num?)?.toInt(),
      categoryId: (category['id'] as num?)?.toInt(),
      categoryName: category['name']?.toString(),
      gallery: galleryItems.map((item) => item.url).toList(growable: false),
      galleryItems: galleryItems,
      variants: variants,
      optionGroups: optionGroups,
    );
  }
}

class CatalogGalleryImage {
  final int? id;
  final String url;
  final String? altText;
  final bool isPrimary;

  const CatalogGalleryImage({
    required this.url,
    this.id,
    this.altText,
    this.isPrimary = false,
  });

  factory CatalogGalleryImage.fromJson(Map<String, dynamic> json) =>
      CatalogGalleryImage(
        id: (json['id'] as num?)?.toInt(),
        url: json['url']?.toString() ?? '',
        altText: json['alt_text']?.toString(),
        isPrimary: json['is_primary'] == true,
      );
}

class CatalogVariantOptionValue {
  final int id;
  final int optionGroupId;

  const CatalogVariantOptionValue({
    required this.id,
    required this.optionGroupId,
  });

  factory CatalogVariantOptionValue.fromJson(Map<String, dynamic> json) =>
      CatalogVariantOptionValue(
        id: (json['id'] as num).toInt(),
        optionGroupId: (json['option_group_id'] as num).toInt(),
      );
}

class CatalogVariant {
  final int id;
  final String name;
  final double priceAdjustment;
  final bool isDefault;
  final bool isAvailable;
  final List<CatalogVariantOptionValue> optionValues;

  const CatalogVariant({
    required this.id,
    required this.name,
    required this.priceAdjustment,
    required this.isDefault,
    required this.isAvailable,
    this.optionValues = const <CatalogVariantOptionValue>[],
  });

  Set<int> get optionValueIds => optionValues.map((value) => value.id).toSet();

  factory CatalogVariant.fromJson(Map<String, dynamic> json) => CatalogVariant(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        priceAdjustment: _catalogDouble(json['price_adjustment']),
        isDefault: json['is_default'] == true,
        isAvailable: json['is_available'] == true,
        optionValues: (json['option_values'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (item) => CatalogVariantOptionValue.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
      );
}

class CatalogOptionGroup {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String selectionType;
  final bool isRequired;
  final int minSelect;
  final int? maxSelect;
  final List<CatalogOptionValue> values;

  const CatalogOptionGroup({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.minSelect,
    required this.maxSelect,
    required this.values,
    this.code = '',
    this.description,
    this.selectionType = 'single',
  });

  bool get isSingle => selectionType.trim().toLowerCase() != 'multiple';

  int get effectiveMinimum => isRequired && minSelect < 1 ? 1 : minSelect;

  factory CatalogOptionGroup.fromJson(Map<String, dynamic> json) =>
      CatalogOptionGroup(
        id: (json['id'] as num).toInt(),
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        selectionType: json['selection_type']?.toString() ?? 'single',
        isRequired: json['is_required'] == true,
        minSelect: (json['min_select'] as num?)?.toInt() ?? 0,
        maxSelect: (json['max_select'] as num?)?.toInt(),
        values: (json['values'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (item) => CatalogOptionValue.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
      );
}

class CatalogOptionValue {
  final int id;
  final String code;
  final String name;
  final double priceAdjustment;
  final bool isDefault;

  const CatalogOptionValue({
    required this.id,
    required this.name,
    required this.priceAdjustment,
    required this.isDefault,
    this.code = '',
  });

  factory CatalogOptionValue.fromJson(Map<String, dynamic> json) =>
      CatalogOptionValue(
        id: (json['id'] as num).toInt(),
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        priceAdjustment: _catalogDouble(json['price_adjustment']),
        isDefault: json['is_default'] == true,
      );
}

class CatalogVariantAvailability {
  final int id;
  final bool available;
  final String status;
  final bool stockTracked;

  const CatalogVariantAvailability({
    required this.id,
    required this.available,
    required this.status,
    required this.stockTracked,
  });

  factory CatalogVariantAvailability.fromJson(Map<String, dynamic> json) =>
      CatalogVariantAvailability(
        id: (json['id'] as num).toInt(),
        available: json['available'] == true,
        status: json['status']?.toString() ?? 'unavailable',
        stockTracked: json['stock_tracked'] == true,
      );
}

class CatalogProductAvailability {
  final int branchId;
  final int productId;
  final bool available;
  final String status;
  final bool stockTracked;
  final List<CatalogVariantAvailability> variants;

  const CatalogProductAvailability({
    required this.branchId,
    required this.productId,
    required this.available,
    required this.status,
    required this.stockTracked,
    this.variants = const <CatalogVariantAvailability>[],
  });

  CatalogVariantAvailability? variant(int id) {
    for (final row in variants) {
      if (row.id == id) return row;
    }
    return null;
  }

  bool variantAvailable(int id) => variant(id)?.available ?? false;

  factory CatalogProductAvailability.fromJson(Map<String, dynamic> json) =>
      CatalogProductAvailability(
        branchId: (json['branch_id'] as num?)?.toInt() ?? 0,
        productId: (json['product_id'] as num?)?.toInt() ?? 0,
        available: json['available'] == true,
        status: json['status']?.toString() ?? 'unavailable',
        stockTracked: json['stock_tracked'] == true,
        variants: (json['variants'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (item) => CatalogVariantAvailability.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
      );
}

class CatalogPricingQuote {
  final int branchId;
  final String currency;
  final String orderType;
  final int productId;
  final int? variantId;
  final double unitTotal;
  final double lineTotal;
  final double taxTotal;
  final double orderTotal;

  const CatalogPricingQuote({
    required this.branchId,
    required this.currency,
    required this.orderType,
    required this.productId,
    required this.unitTotal,
    required this.lineTotal,
    required this.taxTotal,
    required this.orderTotal,
    this.variantId,
  });

  factory CatalogPricingQuote.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? const <dynamic>[];
    final first = rawItems.whereType<Map>().isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(rawItems.whereType<Map>().first);

    return CatalogPricingQuote(
      branchId: (json['branch_id'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'EGP',
      orderType: json['order_type']?.toString() ?? 'pickup',
      productId: (first['product_id'] as num?)?.toInt() ?? 0,
      variantId: (first['variant_id'] as num?)?.toInt(),
      unitTotal: _catalogDouble(first['unit_total']),
      lineTotal: _catalogDouble(first['line_total']),
      taxTotal: _catalogDouble(json['tax_total']),
      orderTotal: _catalogDouble(json['total']),
    );
  }

  String get displayUnitTotal {
    final formatted = unitTotal == unitTotal.roundToDouble()
        ? unitTotal.toStringAsFixed(0)
        : unitTotal.toStringAsFixed(2);
    return '$currency $formatted';
  }
}

Branch branchFromApi(Map<String, dynamic> json) {
  final location = json['location'] is Map
      ? Map<String, dynamic>.from(json['location'] as Map)
      : const <String, dynamic>{};
  final capabilities = json['capabilities'] is Map
      ? Map<String, dynamic>.from(json['capabilities'] as Map)
      : const <String, dynamic>{};
  final contact = json['contact'] is Map
      ? Map<String, dynamic>.from(json['contact'] as Map)
      : const <String, dynamic>{};
  final status = json['status'] is Map
      ? Map<String, dynamic>.from(json['status'] as Map)
      : const <String, dynamic>{};

  final hasOpenStatus =
      status.containsKey('is_open_now') || status.containsKey('is_open');
  final bool? isOpen = hasOpenStatus
      ? status['is_open_now'] == true || status['is_open'] == true
      : null;
  final explicitStatusLabel = status['label']?.toString().trim();

  return Branch(
    id: (json['id'] as num).toInt(),
    name: json['name']?.toString() ?? '',
    latitude: (location['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (location['longitude'] as num?)?.toDouble() ?? 0,
    deliveryEnabled: capabilities['delivery'] == true,
    pickupEnabled: capabilities['pickup'] == true,
    phone: contact['phone']?.toString(),
    address: location['address']?.toString(),
    city: location['city']?.toString(),
    countryCode: location['country_code']?.toString(),
    currency: json['currency']?.toString(),
    imageUrl: json['image_url']?.toString(),
    isOpen: isOpen,
    statusLabel: explicitStatusLabel?.isNotEmpty == true
        ? explicitStatusLabel
        : isOpen == null
            ? null
            : isOpen
                ? 'Open'
                : 'Closed',
  );
}
