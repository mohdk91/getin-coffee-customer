import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/customer_auth_store.dart';
import '../../core/catalog/customer_catalog_models.dart';
import '../../core/catalog/customer_catalog_store.dart';
import '../../core/favorites/customer_favorites_store.dart';
import '../../core/products/product_type.dart';
import '../../core/theme/app_colors.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_screen.dart';
import 'live_product_configuration.dart';
import 'product_merchandising_preview.dart';

class LiveProductDetailScreen extends StatefulWidget {
  final int branchId;
  final String branchName;
  final String serviceType;
  final CatalogProduct summary;
  final CartItem? editingItem;

  const LiveProductDetailScreen({
    super.key,
    required this.branchId,
    required this.branchName,
    required this.serviceType,
    required this.summary,
    this.editingItem,
  });

  @override
  State<LiveProductDetailScreen> createState() =>
      _LiveProductDetailScreenState();
}

class _LiveProductDetailScreenState extends State<LiveProductDetailScreen> {
  CatalogProduct? _product;
  CatalogProductAvailability? _availability;
  LiveProductConfiguration? _configuration;
  CatalogPricingQuote? _quote;
  Object? _error;
  Object? _quoteError;
  bool _loading = true;
  bool _quoting = false;
  bool _saving = false;
  bool _addedToCart = false;
  final Set<int> _pairingSavingIds = <int>{};
  late int _quantity;
  Timer? _quoteTimer;
  int _quoteGeneration = 0;

  CatalogProduct get _displayProduct => _product ?? widget.summary;

  FavoriteProductEntry get _favoriteEntry {
    final product = _displayProduct;
    return FavoriteProductEntry.fromProduct(
      serverProductId: product.id,
      name: product.name,
      description: product.shortDescription,
      image: product.imageUrl ?? '',
      price: _quote?.displayUnitTotal ?? product.displayPrice,
      branchName: widget.branchName,
      serviceType: widget.serviceType,
    );
  }

  Future<void> _toggleFavorite() async {
    final saved = await CustomerFavoritesStore.instance.toggle(_favoriteEntry);
    if (!mounted) return;
    final error = CustomerFavoritesStore.instance.lastError;
    _showMessage(
      error == null
          ? (saved ? 'Added to Favorites.' : 'Removed from Favorites.')
          : 'Could not update Favorites. Your previous state was restored.',
    );
  }

  @override
  void initState() {
    super.initState();
    _quantity = widget.editingItem?.quantity ?? 1;
    _load();
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _quoteTimer?.cancel();
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _quote = null;
        _quoteError = null;
        _addedToCart = false;
      });
    }

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        CustomerCatalogStore.instance.loadProduct(
          widget.branchId,
          widget.summary.id,
        ),
        CustomerCatalogStore.instance.loadAvailability(
          widget.branchId,
          widget.summary.id,
        ),
      ]);
      if (!mounted) return;
      final product = results[0] as CatalogProduct?;
      final availability = results[1] as CatalogProductAvailability?;
      if (product == null || availability == null) {
        throw StateError('Live product detail is unavailable.');
      }
      final configuration = LiveProductConfiguration(
        product: product,
        availability: availability,
        initialVariantId: widget.editingItem?.variantId,
        initialOptionValueIds:
            widget.editingItem?.optionValueIds ?? const <int>[],
      );
      setState(() {
        _product = product;
        _availability = availability;
        _configuration = configuration;
        _loading = false;
      });
      _scheduleQuote(immediate: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _scheduleQuote({bool immediate = false}) {
    _quoteTimer?.cancel();
    final configuration = _configuration;
    if (configuration == null || !configuration.complete) {
      setState(() {
        _quote = null;
        _quoteError = null;
        _quoting = false;
      });
      return;
    }

    setState(() {
      _quote = null;
      _quoteError = null;
    });
    if (immediate) {
      unawaited(_refreshQuote());
      return;
    }
    _quoteTimer = Timer(const Duration(milliseconds: 280), () {
      unawaited(_refreshQuote());
    });
  }

  Future<void> _refreshQuote() async {
    final product = _product;
    final configuration = _configuration;
    if (product == null || configuration == null || !configuration.complete) {
      return;
    }

    final generation = ++_quoteGeneration;
    if (mounted) setState(() => _quoting = true);
    try {
      final quote = await CustomerCatalogStore.instance.quoteProduct(
        branchId: widget.branchId,
        orderType: widget.serviceType,
        productId: product.id,
        quantity: _quantity,
        variantId: configuration.variantId,
        optionValueIds: configuration.optionValueIds,
      );
      if (!mounted || generation != _quoteGeneration) return;
      if (quote == null) {
        throw StateError('Pricing quote is unavailable.');
      }
      setState(() {
        _quote = quote;
        _quoteError = null;
        _quoting = false;
      });
    } catch (error) {
      if (!mounted || generation != _quoteGeneration) return;
      setState(() {
        _quote = null;
        _quoteError = error;
        _quoting = false;
      });
    }
  }

  void _selectVariant(int id) {
    final configuration = _configuration;
    if (configuration == null) return;
    setState(() {
      configuration.selectVariant(id);
      _addedToCart = false;
    });
    _scheduleQuote();
  }

  void _toggleOption(
    CatalogOptionGroup group,
    CatalogOptionValue value,
  ) {
    final configuration = _configuration;
    if (configuration == null) return;
    setState(() {
      configuration.toggleValue(group, value);
      _addedToCart = false;
    });
    _scheduleQuote();
  }

  void _changeQuantity(int delta) {
    final next = (_quantity + delta).clamp(1, 99).toInt();
    if (next == _quantity) return;
    setState(() {
      _quantity = next;
      _addedToCart = false;
    });
    _scheduleQuote();
  }

  String _lineTotal(CatalogProduct product) {
    final quote = _quote;
    if (quote != null) {
      return product.money(quote.lineTotal);
    }
    return product.money(product.price * _quantity);
  }

  Future<void> _openCart() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CartScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _saveToCart() async {
    final product = _product;
    final configuration = _configuration;
    if (product == null || configuration == null || !configuration.complete) {
      return;
    }

    setState(() => _saving = true);
    try {
      final freshAvailability = await CustomerCatalogStore.instance
          .loadAvailability(widget.branchId, product.id);
      if (freshAvailability == null || !freshAvailability.available) {
        if (freshAvailability != null) {
          configuration.replaceAvailability(freshAvailability);
        }
        if (!mounted) return;
        setState(() {
          _availability = freshAvailability;
          _quote = null;
        });
        _showMessage('This product is no longer available at this branch.');
        return;
      }

      configuration.replaceAvailability(freshAvailability);
      if (!configuration.complete) {
        if (!mounted) return;
        setState(() {
          _availability = freshAvailability;
          _quote = null;
        });
        _showMessage('Your selected configuration is no longer available.');
        return;
      }

      final freshQuote = await CustomerCatalogStore.instance.quoteProduct(
        branchId: widget.branchId,
        orderType: widget.serviceType,
        productId: product.id,
        quantity: _quantity,
        variantId: configuration.variantId,
        optionValueIds: configuration.optionValueIds,
      );
      if (freshQuote == null) {
        throw StateError('Live pricing is unavailable.');
      }
      if (!mounted) return;

      final labels = configuration.selectedLabels;
      final image = product.imageUrl ??
          (product.gallery.isNotEmpty ? product.gallery.first : '');
      final item = CartItem(
        branchId: widget.branchId,
        productId: product.id,
        variantId: configuration.variantId,
        optionValueIds: configuration.optionValueIds,
        name: product.name,
        description: product.shortDescription,
        image: image,
        branchName: widget.branchName,
        serviceType: widget.serviceType,
        currency: freshQuote.currency,
        basePrice: product.price,
        unitPrice: freshQuote.unitTotal,
        quantity: _quantity,
        strength: 'Regular',
        sweetness: 'Regular',
        addOns: labels,
        productType: GetinProductCatalog.typeFromCategory(
          product.categoryName ?? '',
        ),
        variant: configuration.resolvedVariant?.name,
      );

      final cart = CartController.instance;
      final editing = widget.editingItem;
      if (editing != null) {
        cart.replaceItem(
          originalSignature: editing.signature,
          replacement: item,
        );
        if (mounted) Navigator.of(context).pop();
        return;
      }

      if (!cart.canAccept(item)) {
        final replace = await _confirmCartReplacement(cart, item);
        if (!replace || !mounted) return;
        cart.clear();
      }

      final added = cart.addOrMerge(item);
      if (!added) {
        _showMessage('Could not add this configuration to the current cart.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _availability = freshAvailability;
        _quote = freshQuote;
        _addedToCart = true;
      });
      _showMessage('${product.name} added to cart.');
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Could not verify live availability and price. Nothing was added.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmCartReplacement(
    CartController cart,
    CartItem item,
  ) async {
    final existingBranch = cart.cartBranchName ?? 'another branch';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start a new cart?'),
        content: Text(
          'Your cart contains items from $existingBranch. '
          'This live item belongs to ${item.branchName} and '
          '${item.serviceType}. Replace the current cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep cart'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Replace cart'),
          ),
        ],
      ),
    );
    return result == true;
  }

  bool _showGuestMerchandisingPreview(CatalogProduct product) {
    return CustomerCatalogStore.instance.usesApi &&
        !CustomerAuthStore.instance.isAuthenticated &&
        product.variants.isEmpty &&
        product.optionGroups.isEmpty;
  }

  bool _foodLike(CatalogProduct product) {
    final source =
        '${product.categoryName ?? ''} ${product.name}'.trim().toLowerCase();
    return source.contains('bakery') ||
        source.contains('food') ||
        source.contains('sandwich') ||
        source.contains('croissant') ||
        source.contains('muffin');
  }

  List<CatalogProduct> _oftenOrderedWith(CatalogProduct product) {
    final all = CustomerCatalogStore.instance
        .productsForBranch(widget.branchId)
        .where((candidate) => candidate.id != product.id)
        .toList(growable: false);
    if (all.isEmpty) return const <CatalogProduct>[];

    final currentFoodLike = _foodLike(product);
    final complementary = all
        .where((candidate) => _foodLike(candidate) != currentFoodLike)
        .toList(growable: false);
    final sameFamily = all
        .where((candidate) => _foodLike(candidate) == currentFoodLike)
        .toList(growable: false);

    return <CatalogProduct>[...complementary, ...sameFamily]
        .take(3)
        .toList(growable: false);
  }

  Future<void> _openPairing(CatalogProduct product) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveProductDetailScreen(
          branchId: widget.branchId,
          branchName: widget.branchName,
          serviceType: widget.serviceType,
          summary: product,
        ),
      ),
    );
  }

  Future<void> _quickAddPairing(CatalogProduct summary) async {
    if (_pairingSavingIds.contains(summary.id)) return;

    setState(() => _pairingSavingIds.add(summary.id));

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        CustomerCatalogStore.instance.loadProduct(
          widget.branchId,
          summary.id,
        ),
        CustomerCatalogStore.instance.loadAvailability(
          widget.branchId,
          summary.id,
        ),
      ]);
      if (!mounted) return;

      final product = results[0] as CatalogProduct?;
      final availability = results[1] as CatalogProductAvailability?;

      if (product == null || availability == null || !availability.available) {
        _showMessage('This product is currently unavailable at this branch.');
        return;
      }

      // Never silently choose a variant or required customization.
      // For configurable products the + button opens the authoritative
      // product configurator; simple products are added in one tap.
      if (product.isVariable || product.optionGroups.isNotEmpty) {
        await _openPairing(product);
        return;
      }

      final freshQuote = await CustomerCatalogStore.instance.quoteProduct(
        branchId: widget.branchId,
        orderType: widget.serviceType,
        productId: product.id,
        quantity: 1,
        variantId: null,
        optionValueIds: const <int>[],
      );
      if (freshQuote == null) {
        throw StateError('Live pricing is unavailable.');
      }
      if (!mounted) return;

      final image = product.imageUrl ??
          (product.gallery.isNotEmpty ? product.gallery.first : '');

      final item = CartItem(
        branchId: widget.branchId,
        productId: product.id,
        variantId: null,
        optionValueIds: const <int>[],
        name: product.name,
        description: product.shortDescription,
        image: image,
        branchName: widget.branchName,
        serviceType: widget.serviceType,
        currency: freshQuote.currency,
        basePrice: product.price,
        unitPrice: freshQuote.unitTotal,
        quantity: 1,
        strength: 'Regular',
        sweetness: 'Regular',
        addOns: const <String>[],
        productType: GetinProductCatalog.typeFromCategory(
          product.categoryName ?? '',
        ),
      );

      final cart = CartController.instance;

      if (!cart.canAccept(item)) {
        final replace = await _confirmCartReplacement(cart, item);
        if (!replace || !mounted) return;
        cart.clear();
      }

      final added = cart.addOrMerge(item);
      if (!added) {
        _showMessage('Could not add this item to the current cart.');
        return;
      }

      _showMessage('${product.name} added to cart.');
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Could not verify live availability and price. Nothing was added.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _pairingSavingIds.remove(summary.id));
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final product = _displayProduct;
    final availability = _availability;
    final configuration = _configuration;
    final image = product.imageUrl ?? widget.summary.imageUrl ?? '';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          AnimatedBuilder(
            animation: CustomerFavoritesStore.instance,
            builder: (context, _) {
              final favorite = CustomerFavoritesStore.instance.containsProduct(
                serverProductId: product.id,
                name: product.name,
              );
              return IconButton(
                tooltip:
                    favorite ? 'Remove from Favorites' : 'Add to Favorites',
                onPressed: _toggleFavorite,
                icon: Icon(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _LiveProductHero(
                    image: image,
                    name: product.name,
                    description: product.description?.trim().isNotEmpty == true
                        ? product.description!
                        : product.shortDescription,
                    price: _quote?.displayUnitTotal ?? product.displayPrice,
                    branchName: widget.branchName,
                    quoting: _quoting,
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const _LiveProductStatusCard(
                      icon: Icons.sync_rounded,
                      title: 'Loading product options',
                      body: 'Checking availability and available choices.',
                    )
                  else if (_error != null)
                    _LiveProductErrorCard(onRetry: _load)
                  else ...[
                    _LiveProductStatusCard(
                      icon: availability?.available == true
                          ? Icons.check_circle_outline_rounded
                          : Icons.inventory_2_outlined,
                      title: availability?.available == true
                          ? 'Available at this branch'
                          : 'Currently unavailable',
                      body: availability?.available == true
                          ? 'Customize your item below.'
                          : 'This branch reports ${availability?.status ?? 'unavailable'}.',
                    ),
                    if (configuration != null) ...[
                      const SizedBox(height: 14),
                      ..._configurationCards(product, configuration),
                      if (_showGuestMerchandisingPreview(product)) ...[
                        if (_configurationCards(product, configuration)
                            .isNotEmpty)
                          const SizedBox(height: 14),
                        GuestProductMerchandisingPreview(
                          currency: product.currency,
                          productName: product.name,
                          categoryName: product.categoryName,
                        ),
                      ],
                      if (product.galleryItems.length > 1) ...[
                        const SizedBox(height: 14),
                        _LiveProductGallery(product: product),
                      ],
                      const SizedBox(height: 14),
                      _LiveProductInformation(product: product),
                      if (_oftenOrderedWith(product).isNotEmpty) ...[
                        const SizedBox(height: 18),
                        LiveOftenOrderedWith(
                          products: _oftenOrderedWith(product),
                          addingProductIds: _pairingSavingIds,
                          onProductTap: _openPairing,
                          onQuickAdd: _quickAddPairing,
                        ),
                      ],
                      if (_quoteError != null) ...[
                        const SizedBox(height: 14),
                        _LiveProductStatusCard(
                          icon: Icons.error_outline_rounded,
                          title: 'Could not update price',
                          body:
                              'Please try again before adding this item to your cart.',
                          actionLabel: 'Retry price',
                          onAction: _refreshQuote,
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ),
          if (!_loading && _error == null && configuration != null)
            _LiveProductBottomBar(
              quantity: _quantity,
              total: _lineTotal(product),
              enabled: !_saving &&
                  (_addedToCart ||
                      (configuration.complete && _quote != null && !_quoting)),
              message: _addedToCart
                  ? 'Added to cart'
                  : configuration.complete
                      ? (_quote != null ? 'Price confirmed' : 'Updating price')
                      : 'Choose required options',
              primaryLabel: widget.editingItem == null
                  ? (_addedToCart
                      ? 'View cart'
                      : (_saving ? 'Checking…' : 'Add to cart'))
                  : (_saving ? 'Checking…' : 'Update item'),
              onDecrease: () => _changeQuantity(-1),
              onIncrease: () => _changeQuantity(1),
              onPrimary: widget.editingItem == null && _addedToCart
                  ? _openCart
                  : _saveToCart,
            ),
        ],
      ),
    );
  }

  List<Widget> _configurationCards(
    CatalogProduct product,
    LiveProductConfiguration configuration,
  ) {
    final cards = <Widget>[];

    if (product.isVariable && !configuration.usesMappedVariants) {
      cards.add(
        _LiveVariantSection(
          variants: configuration.availableVariants.toList(growable: false),
          selectedId: configuration.variantId,
          currency: product.currency,
          onSelected: _selectVariant,
        ),
      );
      cards.add(const SizedBox(height: 14));
    }

    for (final group in product.optionGroups) {
      cards.add(
        _LiveOptionGroupSection(
          group: group,
          currency: product.currency,
          selectedIds: configuration.selectedForGroup(group.id),
          isEnabled: (value) => configuration.isValueEnabled(group, value),
          onToggle: (value) => _toggleOption(group, value),
        ),
      );
      cards.add(const SizedBox(height: 14));
    }

    if (cards.isNotEmpty) cards.removeLast();
    return cards;
  }
}

class _LiveProductHero extends StatelessWidget {
  final String image;
  final String name;
  final String description;
  final String price;
  final String branchName;
  final bool quoting;

  const _LiveProductHero({
    required this.image,
    required this.name,
    required this.description,
    required this.price,
    required this.branchName,
    required this.quoting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.55,
            child: _LiveRemoteAwareImage(image: image),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        branchName,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (quoting) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.6),
                      ),
                      const SizedBox(width: 7),
                    ],
                    Text(
                      price,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveVariantSection extends StatelessWidget {
  final List<CatalogVariant> variants;
  final int? selectedId;
  final String currency;
  final ValueChanged<int> onSelected;

  const _LiveVariantSection({
    required this.variants,
    required this.selectedId,
    required this.currency,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _LiveSectionCard(
      title: 'Variant',
      subtitle: 'Choose 1 · Required',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: variants
            .map(
              (variant) => _LiveChoiceChip(
                label: variant.name,
                surcharge: _surcharge(currency, variant.priceAdjustment),
                selected: selectedId == variant.id,
                enabled: true,
                onTap: () => onSelected(variant.id),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _LiveOptionGroupSection extends StatelessWidget {
  final CatalogOptionGroup group;
  final String currency;
  final Set<int> selectedIds;
  final bool Function(CatalogOptionValue value) isEnabled;
  final ValueChanged<CatalogOptionValue> onToggle;

  const _LiveOptionGroupSection({
    required this.group,
    required this.currency,
    required this.selectedIds,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final maximum = group.maxSelect;
    final rule = group.isSingle
        ? 'Choose 1'
        : maximum == null
            ? 'Choose ${group.effectiveMinimum}+'
            : 'Choose ${group.effectiveMinimum}–$maximum';
    final required = group.effectiveMinimum > 0 ? 'Required' : 'Optional';

    return _LiveSectionCard(
      title: group.name,
      subtitle: [
        if (group.description?.trim().isNotEmpty == true) group.description!,
        '$rule · $required',
      ].join('\n'),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: group.values
            .map(
              (value) => _LiveChoiceChip(
                label: value.name,
                surcharge: _surcharge(currency, value.priceAdjustment),
                selected: selectedIds.contains(value.id),
                enabled: isEnabled(value),
                onTap: () => onToggle(value),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _LiveSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _LiveSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LiveChoiceChip extends StatelessWidget {
  final String label;
  final String? surcharge;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _LiveChoiceChip({
    required this.label,
    required this.surcharge,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.beige.withOpacity(0.35) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          constraints: const BoxConstraints(minWidth: 110, minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 17,
                color: enabled ? AppColors.green : AppColors.muted,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: enabled ? AppColors.green : AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (surcharge != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        surcharge!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveProductGallery extends StatelessWidget {
  final CatalogProduct product;

  const _LiveProductGallery({required this.product});

  @override
  Widget build(BuildContext context) {
    return _LiveSectionCard(
      title: 'Gallery',
      subtitle: '${product.galleryItems.length} product images',
      child: SizedBox(
        height: 126,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: product.galleryItems.length,
          separatorBuilder: (_, __) => const SizedBox(width: 9),
          itemBuilder: (context, index) {
            final image = product.galleryItems[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                width: 126,
                child: _LiveRemoteAwareImage(image: image.url),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LiveProductInformation extends StatelessWidget {
  final CatalogProduct product;

  const _LiveProductInformation({required this.product});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (product.description?.trim().isNotEmpty == true)
        ('Description', product.description!.trim()),
      if (product.ingredients?.trim().isNotEmpty == true)
        ('Ingredients', product.ingredients!.trim()),
      if (product.allergens?.trim().isNotEmpty == true)
        ('Allergens', product.allergens!.trim()),
      if (product.calories != null) ('Calories', '${product.calories} kcal'),
      if (product.preparationTimeMinutes != null)
        ('Preparation', '${product.preparationTimeMinutes} min'),
    ];

    if (rows.isEmpty) {
      return const _LiveProductStatusCard(
        icon: Icons.info_outline_rounded,
        title: 'Product information',
        body: 'No additional product information is published yet.',
      );
    }

    return _LiveSectionCard(
      title: 'Product Information',
      subtitle: 'Published product details',
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _LiveInfoRow(title: rows[index].$1, value: rows[index].$2),
            if (index != rows.length - 1)
              const Divider(height: 18, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _LiveInfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _LiveInfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveProductStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _LiveProductStatusCard({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveProductErrorCard extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _LiveProductErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load product details',
            style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          // Legacy contract marker: No demo configuration will be substituted.
          const Text(
            'Product details are temporarily unavailable. Please try again.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.beige,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _LiveProductBottomBar extends StatelessWidget {
  final int quantity;
  final String total;
  final bool enabled;
  final String message;
  final String primaryLabel;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onPrimary;

  const _LiveProductBottomBar({
    required this.quantity,
    required this.total,
    required this.enabled,
    required this.message,
    required this.primaryLabel,
    required this.onDecrease,
    required this.onIncrease,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: onDecrease,
                        icon: const Icon(
                          Icons.remove_rounded,
                          color: AppColors.green,
                        ),
                      ),
                      SizedBox(
                        width: 22,
                        child: Center(
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onIncrease,
                        icon: const Icon(
                          Icons.add_rounded,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: enabled ? onPrimary : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.beige,
                        disabledBackgroundColor:
                            AppColors.muted.withOpacity(0.18),
                        disabledForegroundColor: AppColors.muted,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              primaryLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            total,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRemoteAwareImage extends StatelessWidget {
  final String image;

  const _LiveRemoteAwareImage({required this.image});

  @override
  Widget build(BuildContext context) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.cream),
      );
    }
    if (image.trim().isEmpty) {
      return const ColoredBox(color: AppColors.cream);
    }
    return Image.asset(image, fit: BoxFit.cover);
  }
}

String? _surcharge(String currency, double value) {
  if (value == 0) return null;
  final absolute = value.abs();
  final formatted = absolute == absolute.roundToDouble()
      ? absolute.toStringAsFixed(0)
      : absolute.toStringAsFixed(2);
  final sign = value > 0 ? '+' : '−';
  return '$sign $currency $formatted';
}
