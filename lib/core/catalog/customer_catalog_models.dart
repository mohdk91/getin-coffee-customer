import '../../features/location/models/branch.dart';

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
  final String? imageUrl;
  final String productType;
  final bool isFeatured;
  final double price;
  final String currency;
  final int? categoryId;
  final String? categoryName;
  final List<String> gallery;
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
    this.imageUrl,
    this.categoryId,
    this.categoryName,
    this.gallery = const <String>[],
    this.variants = const <CatalogVariant>[],
    this.optionGroups = const <CatalogOptionGroup>[],
  });

  String get displayPrice {
    final normalized = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '$currency $normalized';
  }

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    final category = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : const <String, dynamic>{};
    final gallery = (json['gallery'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => item['url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    final variants = (json['variants'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => CatalogVariant.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final optionGroups = (json['option_groups'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => CatalogOptionGroup.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return CatalogProduct(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      productType: json['product_type']?.toString() ?? '',
      isFeatured: json['is_featured'] == true,
      price: (json['catalog_price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'EGP',
      categoryId: (category['id'] as num?)?.toInt(),
      categoryName: category['name']?.toString(),
      gallery: gallery,
      variants: variants,
      optionGroups: optionGroups,
    );
  }
}

class CatalogVariant {
  final int id;
  final String name;
  final double priceAdjustment;
  final bool isDefault;
  final bool isAvailable;

  const CatalogVariant({
    required this.id,
    required this.name,
    required this.priceAdjustment,
    required this.isDefault,
    required this.isAvailable,
  });

  factory CatalogVariant.fromJson(Map<String, dynamic> json) => CatalogVariant(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        priceAdjustment: (json['price_adjustment'] as num?)?.toDouble() ?? 0,
        isDefault: json['is_default'] == true,
        isAvailable: json['is_available'] == true,
      );
}

class CatalogOptionGroup {
  final int id;
  final String name;
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
  });

  factory CatalogOptionGroup.fromJson(Map<String, dynamic> json) =>
      CatalogOptionGroup(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        isRequired: json['is_required'] == true,
        minSelect: (json['min_select'] as num?)?.toInt() ?? 0,
        maxSelect: (json['max_select'] as num?)?.toInt(),
        values: (json['values'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => CatalogOptionValue.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false),
      );
}

class CatalogOptionValue {
  final int id;
  final String name;
  final double priceAdjustment;
  final bool isDefault;

  const CatalogOptionValue({
    required this.id,
    required this.name,
    required this.priceAdjustment,
    required this.isDefault,
  });

  factory CatalogOptionValue.fromJson(Map<String, dynamic> json) =>
      CatalogOptionValue(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        priceAdjustment: (json['price_adjustment'] as num?)?.toDouble() ?? 0,
        isDefault: json['is_default'] == true,
      );
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
    imageUrl: json['image_url']?.toString(),
    isOpen: status['is_open'] == true,
    statusLabel: status['label']?.toString(),
  );
}
