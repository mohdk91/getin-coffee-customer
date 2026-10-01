import '../../core/catalog/customer_catalog_models.dart';

class LiveProductConfiguration {
  final CatalogProduct product;
  CatalogProductAvailability availability;

  final Map<int, Set<int>> _selectedByGroup = <int, Set<int>>{};
  int? _explicitVariantId;

  LiveProductConfiguration({
    required this.product,
    required this.availability,
    int? initialVariantId,
    List<int> initialOptionValueIds = const <int>[],
  }) {
    _seed(
      initialVariantId: initialVariantId,
      initialOptionValueIds: initialOptionValueIds,
    );
  }

  Iterable<CatalogVariant> get availableVariants => product.variants.where(
        (variant) =>
            variant.isAvailable &&
            (availability.variants.isEmpty ||
                availability.variantAvailable(variant.id)),
      );

  Set<int> get variantGroupIds => product.variants
      .expand((variant) => variant.optionValues)
      .map((value) => value.optionGroupId)
      .toSet();

  bool get usesMappedVariants =>
      product.isVariable && variantGroupIds.isNotEmpty;

  CatalogVariant? get resolvedVariant {
    if (!product.isVariable) return null;

    if (!usesMappedVariants) {
      final id = _explicitVariantId;
      if (id == null) return null;
      for (final variant in availableVariants) {
        if (variant.id == id) return variant;
      }
      return null;
    }

    final selectedDefiningIds = <int>{};
    for (final groupId in variantGroupIds) {
      selectedDefiningIds.addAll(_selectedByGroup[groupId] ?? const <int>{});
    }

    for (final variant in availableVariants) {
      final variantIds = variant.optionValues
          .where((value) => variantGroupIds.contains(value.optionGroupId))
          .map((value) => value.id)
          .toSet();
      if (_setEquals(variantIds, selectedDefiningIds)) return variant;
    }
    return null;
  }

  int? get variantId => resolvedVariant?.id;

  List<int> get optionValueIds {
    final ids = _selectedByGroup.values.expand((values) => values).toSet();
    final result = ids.toList(growable: false)..sort();
    return result;
  }

  List<String> get selectedLabels {
    final labels = <String>[];
    final variant = resolvedVariant;
    if (variant != null && variant.name.trim().isNotEmpty) {
      labels.add(variant.name.trim());
    }
    for (final group in product.optionGroups) {
      final selected = _selectedByGroup[group.id] ?? const <int>{};
      for (final value in group.values) {
        if (selected.contains(value.id) && !labels.contains(value.name)) {
          labels.add(value.name);
        }
      }
    }
    return labels;
  }

  bool get complete {
    if (!availability.available) return false;
    if (product.isVariable && resolvedVariant == null) return false;

    for (final group in product.optionGroups) {
      final count = (_selectedByGroup[group.id] ?? const <int>{}).length;
      if (count < group.effectiveMinimum) return false;
      final maximum = group.maxSelect;
      if (maximum != null && count > maximum) return false;
      if (group.isSingle && count > 1) return false;
    }
    return true;
  }

  Set<int> selectedForGroup(int groupId) =>
      Set<int>.unmodifiable(_selectedByGroup[groupId] ?? const <int>{});

  bool isSelected(int groupId, int valueId) =>
      _selectedByGroup[groupId]?.contains(valueId) ?? false;

  bool isValueEnabled(CatalogOptionGroup group, CatalogOptionValue value) {
    if (!variantGroupIds.contains(group.id)) return true;

    final candidate = <int>{};
    for (final groupId in variantGroupIds) {
      if (groupId == group.id) continue;
      candidate.addAll(_selectedByGroup[groupId] ?? const <int>{});
    }
    candidate.add(value.id);

    return availableVariants.any((variant) {
      final ids = variant.optionValues.map((row) => row.id).toSet();
      return candidate.every(ids.contains);
    });
  }

  void selectVariant(int variantId) {
    if (!product.isVariable) return;
    CatalogVariant? selected;
    for (final variant in availableVariants) {
      if (variant.id == variantId) {
        selected = variant;
        break;
      }
    }
    if (selected == null) return;

    _explicitVariantId = selected.id;
    if (selected.optionValues.isNotEmpty) {
      for (final row in selected.optionValues) {
        _selectedByGroup[row.optionGroupId] = <int>{row.id};
      }
    }
  }

  void toggleValue(CatalogOptionGroup group, CatalogOptionValue value) {
    if (!isValueEnabled(group, value) && !isSelected(group.id, value.id)) {
      return;
    }

    final selected = _selectedByGroup.putIfAbsent(group.id, () => <int>{});
    if (selected.contains(value.id)) {
      if (selected.length > group.effectiveMinimum) {
        selected.remove(value.id);
      }
      return;
    }

    if (group.isSingle) {
      selected
        ..clear()
        ..add(value.id);
      return;
    }

    final maximum = group.maxSelect;
    if (maximum != null && selected.length >= maximum) return;
    selected.add(value.id);
  }

  void replaceAvailability(CatalogProductAvailability value) {
    availability = value;
    final variant = resolvedVariant;
    if (variant != null &&
        availability.variants.isNotEmpty &&
        !availability.variantAvailable(variant.id)) {
      _explicitVariantId = null;
    }
  }

  void _seed({
    required int? initialVariantId,
    required List<int> initialOptionValueIds,
  }) {
    for (final group in product.optionGroups) {
      _selectedByGroup[group.id] = <int>{};
    }

    CatalogVariant? initialVariant;
    if (initialVariantId != null) {
      for (final variant in availableVariants) {
        if (variant.id == initialVariantId) {
          initialVariant = variant;
          break;
        }
      }
    }
    initialVariant ??= availableVariants.where((variant) => variant.isDefault).firstOrNull;
    initialVariant ??= availableVariants.firstOrNull;

    if (initialVariant != null) {
      _explicitVariantId = initialVariant.id;
      for (final row in initialVariant.optionValues) {
        _selectedByGroup[row.optionGroupId]?.add(row.id);
      }
    }

    final initialIds = initialOptionValueIds.toSet();
    for (final group in product.optionGroups) {
      final selected = _selectedByGroup[group.id]!;
      for (final value in group.values) {
        if (initialIds.contains(value.id)) selected.add(value.id);
      }

      if (group.isSingle && selected.length > 1) {
        final first = selected.first;
        selected
          ..clear()
          ..add(first);
      }

      for (final value in group.values) {
        if (value.isDefault &&
            selected.length < group.effectiveMinimum &&
            (!group.isSingle || selected.isEmpty)) {
          selected.add(value.id);
        }
      }

      for (final value in group.values) {
        if (selected.length >= group.effectiveMinimum) break;
        if (isValueEnabled(group, value)) selected.add(value.id);
      }
    }
  }

  static bool _setEquals(Set<int> left, Set<int> right) =>
      left.length == right.length && left.containsAll(right);
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
