import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/catalog/customer_catalog_models.dart';
import '../../core/catalog/customer_catalog_store.dart';
import '../../core/favorites/customer_favorites_store.dart';
import '../../core/membership/customer_membership_store.dart';
import '../../core/products/product_type.dart';
import '../../core/rewards/reward_earning_policy.dart';
import '../../core/theme/app_colors.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_screen.dart';
import '../reviews/review_screens.dart';
import 'live_product_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String name;
  final String description;
  final String image;
  final String price;
  final String branchName;
  final String serviceType;
  final int? branchId;
  final CatalogProduct? catalogProduct;
  final ProductType? productType;
  final String? productBadge;
  final CartItem? editingItem;

  const ProductDetailScreen({
    super.key,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.branchName,
    required this.serviceType,
    this.branchId,
    this.catalogProduct,
    this.productType,
    this.productBadge,
    this.editingItem,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final GetinProductDefinition _definition;

  String? _size;
  String? _temperature;
  String? _milk;
  String _strength = 'Regular';
  String _sweetness = 'Regular';
  String? _variant;
  String? _warming;
  String? _sauce;
  String? _color;
  int _quantity = 1;

  final Set<String> _addOns = <String>{};

  String? _lastAddedSignature;
  int? _lastAddedQuantity;

  ProductType get _type => _definition.type;

  @override
  void initState() {
    super.initState();
    _definition = GetinProductCatalog.definitionFor(
      widget.name,
      explicitType: widget.productType ?? widget.editingItem?.productType,
      badge: widget.productBadge,
    );

    final editing = widget.editingItem;
    if (editing != null) {
      _size = editing.size;
      _temperature = editing.temperature;
      _milk = editing.milk;
      _strength = editing.strength;
      _sweetness = editing.sweetness;
      _variant = editing.variant;
      _warming = editing.warming;
      _sauce = editing.sauce;
      _color = editing.color;
      _quantity = editing.quantity;
      _addOns.addAll(editing.addOns);
    }

    switch (_type) {
      case ProductType.food:
        _warming ??= 'Warm';
        _variant ??= 'Classic';
        _sauce ??= 'No Sauce';
        break;
      case ProductType.bakery:
        _warming ??= 'Warm';
        _variant ??= 'Classic';
        break;
      case ProductType.drink:
      case ProductType.refreshment:
      case ProductType.merchandise:
        break;
    }
  }

  String get _currency {
    final value = widget.price.trim().split(RegExp(r'\s+')).first;
    return RegExp(r'^[A-Za-z]{3}$').hasMatch(value) ? value : 'EGP';
  }

  double get _basePrice {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(widget.price);
    return double.tryParse(match?.group(1) ?? '') ?? 65;
  }

  bool get _requiredComplete {
    switch (_type) {
      case ProductType.drink:
        return _size != null && _temperature != null && _milk != null;
      case ProductType.refreshment:
        return _size != null && _variant != null;
      case ProductType.food:
      case ProductType.bakery:
        return true;
      case ProductType.merchandise:
        return _variant != null && _size != null && _color != null;
    }
  }

  double get _unitTotal {
    var value = _basePrice;

    switch (_type) {
      case ProductType.drink:
        if (_size == 'Large') value += 10;
        if (_milk == 'Oat Milk' || _milk == 'Coconut Milk') value += 15;
        if (_strength == 'Extra Shot') value += 20;
        break;
      case ProductType.refreshment:
        if (_size == 'Large') value += 10;
        break;
      case ProductType.food:
        if (_variant == 'Extra Cheese') value += 15;
        if (_sauce == 'Honey Mustard' || _sauce == 'Chipotle') value += 10;
        break;
      case ProductType.bakery:
        if (_variant == 'Chocolate Drizzle') value += 15;
        break;
      case ProductType.merchandise:
        if (_variant == 'Straw Lid') value += 25;
        if (_size == '500 ml') value += 50;
        break;
    }

    const addOnPrices = <String, double>{
      'Vanilla': 20,
      'Caramel': 20,
      'Hazelnut': 20,
      'Chocolate Drizzle': 20,
      'Extra Espresso': 25,
      'Extra Berries': 15,
      'Lemon': 10,
      'Mint': 10,
      'Avocado': 20,
      'Extra Turkey': 25,
      'Butter': 10,
      'Cream Cheese': 15,
    };

    for (final addOn in _addOns) {
      value += addOnPrices[addOn] ?? 0;
    }

    return value;
  }

  double get _total => _unitTotal * _quantity;

  void _applyQuickChoice({
    required String size,
    required String temperature,
    required String milk,
    required String strength,
    required String sweetness,
  }) {
    setState(() {
      _size = size;
      _temperature = temperature;
      _milk = milk;
      _strength = strength;
      _sweetness = sweetness;
      _addOns.clear();
    });
  }

  String _money(double value) {
    final whole = value == value.roundToDouble();
    return whole
        ? '$_currency ${value.toStringAsFixed(0)}'
        : '$_currency ${value.toStringAsFixed(2)}';
  }

  int? get _serverVariantId {
    final editing = widget.editingItem;
    final product = widget.catalogProduct;
    if (product == null) return editing?.variantId;

    final selected = _variant?.trim().toLowerCase();
    if (selected != null && selected.isNotEmpty) {
      for (final variant in product.variants) {
        if (variant.isAvailable &&
            variant.name.trim().toLowerCase() == selected) {
          return variant.id;
        }
      }
    }

    for (final variant in product.variants) {
      if (variant.isAvailable && variant.isDefault) return variant.id;
    }
    return null;
  }

  List<int> get _serverOptionValueIds {
    final product = widget.catalogProduct;
    if (product == null) {
      return widget.editingItem?.optionValueIds ?? const <int>[];
    }

    final selectedLabels = <String>{
      if (_size?.trim().isNotEmpty == true) _size!.trim().toLowerCase(),
      if (_temperature?.trim().isNotEmpty == true)
        _temperature!.trim().toLowerCase(),
      if (_milk?.trim().isNotEmpty == true) _milk!.trim().toLowerCase(),
      if (_strength != 'Regular') _strength.trim().toLowerCase(),
      if (_sweetness != 'Regular') _sweetness.trim().toLowerCase(),
      if (_warming?.trim().isNotEmpty == true) _warming!.trim().toLowerCase(),
      if (_sauce?.trim().isNotEmpty == true && _sauce != 'No Sauce')
        _sauce!.trim().toLowerCase(),
      if (_color?.trim().isNotEmpty == true) _color!.trim().toLowerCase(),
      ..._addOns.map((value) => value.trim().toLowerCase()),
    };

    final ids = <int>[];
    for (final group in product.optionGroups) {
      for (final value in group.values) {
        if (selectedLabels.contains(value.name.trim().toLowerCase()) ||
            (value.isDefault &&
                group.isRequired &&
                group.minSelect > 0 &&
                !group.values.any((candidate) => selectedLabels
                    .contains(candidate.name.trim().toLowerCase())))) {
          ids.add(value.id);
        }
      }
    }
    return ids.toSet().toList(growable: false)..sort();
  }

  CartItem? _currentCartItem() {
    if (!_requiredComplete) return null;

    return CartItem(
      branchId: widget.branchId ?? widget.editingItem?.branchId,
      productId: widget.catalogProduct?.id ?? widget.editingItem?.productId,
      variantId: _serverVariantId,
      optionValueIds: _serverOptionValueIds,
      name: widget.name,
      description: widget.description,
      image: widget.image,
      branchName: widget.branchName,
      serviceType: widget.serviceType,
      currency: _currency,
      basePrice: _basePrice,
      unitPrice: _unitTotal,
      quantity: _quantity,
      size: _size,
      temperature: _temperature,
      milk: _milk,
      strength: _strength,
      sweetness: _sweetness,
      addOns: _addOns.toList(),
      productType: _type,
      variant: _variant,
      warming: _warming,
      sauce: _sauce,
      color: _color,
    );
  }

  bool _matchesLastAdded(CartItem? item) {
    if (item == null) return false;
    return _lastAddedSignature == item.signature &&
        _lastAddedQuantity == item.quantity &&
        CartController.instance.containsSignature(item.signature);
  }

  Future<void> _openCart() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _saveToCart() async {
    final item = _currentCartItem();
    if (item == null) return;

    final cart = CartController.instance;
    final editing = widget.editingItem;

    if (editing != null) {
      cart.replaceItem(
        originalSignature: editing.signature,
        replacement: item,
      );
      if (mounted) Navigator.pop(context);
      return;
    }

    if (!cart.canAccept(item)) {
      final existingBranch = cart.cartBranchName ?? 'another branch';
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Start a new cart?'),
            content: Text(
              'Your cart contains items from $existingBranch. '
              'Getin keeps one branch and fulfilment type per cart so stock, pricing and delivery stay accurate.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep cart'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.beige,
                ),
                child: const Text('Clear & add'),
              ),
            ],
          );
        },
      );

      if (replace != true) return;
      cart.clear();
    }

    cart.addOrMerge(item);
    if (!mounted) return;

    setState(() {
      _lastAddedSignature = item.signature;
      _lastAddedQuantity = item.quantity;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.name} added to cart · ${_money(_total)}'),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: _openCart,
        ),
      ),
    );
  }

  FavoriteProductEntry get _favoriteProduct => FavoriteProductEntry.fromProduct(
        serverProductId:
            widget.catalogProduct?.id ?? widget.editingItem?.productId,
        name: widget.name,
        description: widget.description,
        image: widget.image,
        price: widget.price,
        branchName: widget.branchName,
        serviceType: widget.serviceType,
      );

  Future<void> _toggleFavorite() async {
    final added =
        await CustomerFavoritesStore.instance.toggle(_favoriteProduct);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(added ? 'Added to Favorites.' : 'Removed from Favorites.'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  Future<void> _shareProduct() async {
    final slug = CustomerFavoritesStore.productId(widget.name);
    await Share.share(
      '${widget.name} · ${widget.price}\nDiscover it at Getin Coffee.\nhttps://getin.coffee/product/$slug',
      subject: widget.name,
    );
  }

  SliverToBoxAdapter _section(Widget child,
      {double top = 18, double bottom = 0}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, top, 16, bottom),
        child: child,
      ),
    );
  }

  List<Widget> _configurationSlivers() {
    switch (_type) {
      case ProductType.drink:
        return [
          _section(
            _QuickChoices(
              onPopular: () => _applyQuickChoice(
                size: 'Large',
                temperature: 'Iced',
                milk: 'Coconut Milk',
                strength: 'Regular',
                sweetness: 'Regular',
              ),
              onClassic: () => _applyQuickChoice(
                size: 'Regular',
                temperature: 'Iced',
                milk: 'Low Fat',
                strength: 'Regular',
                sweetness: 'No Sugar',
              ),
            ),
          ),
          _section(
            _RequiredSingleChoiceSection(
              title: 'Size',
              subtitle: 'Choose 1',
              selected: _size,
              choices: const [
                _SingleChoice(title: 'Regular', subtitle: '350 ml'),
                _SingleChoice(
                  title: 'Large',
                  subtitle: '450 ml',
                  surcharge: '+ EGP 10',
                ),
              ],
              onSelected: (value) => setState(() => _size = value),
            ),
          ),
          _section(
            _RequiredSingleChoiceSection(
              title: 'Temperature',
              subtitle: 'Choose 1',
              selected: _temperature,
              choices: const [
                _SingleChoice(title: 'Iced', icon: Icons.ac_unit_rounded),
                _SingleChoice(
                  title: 'Hot',
                  icon: Icons.local_fire_department_outlined,
                ),
              ],
              onSelected: (value) => setState(() => _temperature = value),
            ),
          ),
          _section(
            _RequiredSingleChoiceSection(
              title: 'Milk',
              subtitle: 'Choose 1',
              selected: _milk,
              choices: const [
                _SingleChoice(title: 'Full Fat'),
                _SingleChoice(title: 'Low Fat'),
                _SingleChoice(title: 'Oat Milk', surcharge: '+ EGP 15'),
                _SingleChoice(title: 'Coconut Milk', surcharge: '+ EGP 15'),
              ],
              onSelected: (value) => setState(() => _milk = value),
            ),
          ),
          _section(
            _OptionalSingleChoiceSection(
              title: 'Coffee Strength',
              selected: _strength,
              choices: const [
                _SingleChoice(title: 'Regular'),
                _SingleChoice(title: 'Extra Shot', surcharge: '+ EGP 20'),
              ],
              onSelected: (value) => setState(() => _strength = value),
            ),
          ),
          _section(
            _OptionalSingleChoiceSection(
              title: 'Sweetness',
              selected: _sweetness,
              choices: const [
                _SingleChoice(title: 'No Sugar'),
                _SingleChoice(title: 'Less Sweet'),
                _SingleChoice(title: 'Regular'),
                _SingleChoice(title: 'Extra Sweet'),
              ],
              onSelected: (value) => setState(() => _sweetness = value),
            ),
          ),
          _section(
            _AddOnsSection(
              selected: _addOns,
              onChanged: _changeAddOn,
            ),
          ),
        ];
      case ProductType.refreshment:
        return [
          _section(
            _RequiredSingleChoiceSection(
              title: 'Size',
              subtitle: 'Choose 1',
              selected: _size,
              choices: const [
                _SingleChoice(title: 'Regular', subtitle: '350 ml'),
                _SingleChoice(
                  title: 'Large',
                  subtitle: '450 ml',
                  surcharge: '+ EGP 10',
                ),
              ],
              onSelected: (value) => setState(() => _size = value),
            ),
          ),
          _section(
            _RequiredSingleChoiceSection(
              title: 'Ice',
              subtitle: 'Choose 1',
              selected: _variant,
              choices: const [
                _SingleChoice(title: 'Regular Ice'),
                _SingleChoice(title: 'Less Ice'),
                _SingleChoice(title: 'No Ice'),
              ],
              onSelected: (value) => setState(() => _variant = value),
            ),
          ),
          _section(
            _OptionalSingleChoiceSection(
              title: 'Sweetness',
              selected: _sweetness,
              choices: const [
                _SingleChoice(title: 'Less Sweet'),
                _SingleChoice(title: 'Regular'),
                _SingleChoice(title: 'Extra Sweet'),
              ],
              onSelected: (value) => setState(() => _sweetness = value),
            ),
          ),
          _section(
            _AddOnsSection(
              selected: _addOns,
              items: const [
                _AddOn('Extra Berries', '+ EGP 15'),
                _AddOn('Lemon', '+ EGP 10'),
                _AddOn('Mint', '+ EGP 10'),
              ],
              onChanged: _changeAddOn,
            ),
          ),
        ];
      case ProductType.food:
        return [
          _section(
            _OptionalSingleChoiceSection(
              title: 'Preparation',
              selected: _warming ?? 'Warm',
              choices: const [
                _SingleChoice(title: 'Warm'),
                _SingleChoice(title: 'Not warmed'),
              ],
              onSelected: (value) => setState(() => _warming = value),
            ),
          ),
          _section(
            _OptionalSingleChoiceSection(
              title: 'Variant',
              selected: _variant ?? 'Classic',
              choices: const [
                _SingleChoice(title: 'Classic'),
                _SingleChoice(title: 'Extra Cheese', surcharge: '+ EGP 15'),
              ],
              onSelected: (value) => setState(() => _variant = value),
            ),
          ),
          _section(
            _OptionalSingleChoiceSection(
              title: 'Sauce',
              selected: _sauce ?? 'No Sauce',
              choices: const [
                _SingleChoice(title: 'No Sauce'),
                _SingleChoice(title: 'Honey Mustard', surcharge: '+ EGP 10'),
                _SingleChoice(title: 'Chipotle', surcharge: '+ EGP 10'),
              ],
              onSelected: (value) => setState(() => _sauce = value),
            ),
          ),
          _section(
            _AddOnsSection(
              selected: _addOns,
              items: const [
                _AddOn('Avocado', '+ EGP 20'),
                _AddOn('Extra Turkey', '+ EGP 25'),
              ],
              onChanged: _changeAddOn,
            ),
          ),
        ];
      case ProductType.bakery:
        return [
          _section(
            _OptionalSingleChoiceSection(
              title: 'Preparation',
              selected: _warming ?? 'Warm',
              choices: const [
                _SingleChoice(title: 'Warm'),
                _SingleChoice(title: 'Not warmed'),
              ],
              onSelected: (value) => setState(() => _warming = value),
            ),
          ),
          _section(
            _OptionalSingleChoiceSection(
              title: 'Finish',
              selected: _variant ?? 'Classic',
              choices: const [
                _SingleChoice(title: 'Classic'),
                _SingleChoice(
                  title: 'Chocolate Drizzle',
                  surcharge: '+ EGP 15',
                ),
              ],
              onSelected: (value) => setState(() => _variant = value),
            ),
          ),
          _section(
            _AddOnsSection(
              selected: _addOns,
              items: const [
                _AddOn('Butter', '+ EGP 10'),
                _AddOn('Cream Cheese', '+ EGP 15'),
              ],
              onChanged: _changeAddOn,
            ),
          ),
        ];
      case ProductType.merchandise:
        return [
          _section(
            _MerchandiseGallery(image: widget.image),
          ),
          _section(
            _RequiredSingleChoiceSection(
              title: 'Variant',
              subtitle: 'Choose 1',
              selected: _variant,
              choices: const [
                _SingleChoice(title: 'Classic Lid'),
                _SingleChoice(title: 'Straw Lid', surcharge: '+ EGP 25'),
              ],
              onSelected: (value) => setState(() => _variant = value),
            ),
          ),
          _section(
            _RequiredSingleChoiceSection(
              title: 'Size',
              subtitle: 'Choose 1',
              selected: _size,
              choices: const [
                _SingleChoice(title: '350 ml'),
                _SingleChoice(title: '500 ml', surcharge: '+ EGP 50'),
              ],
              onSelected: (value) => setState(() => _size = value),
            ),
          ),
          _section(
            _RequiredSingleChoiceSection(
              title: 'Color',
              subtitle: 'Choose 1',
              selected: _color,
              choices: const [
                _SingleChoice(title: 'Forest Green'),
                _SingleChoice(title: 'Cream'),
                _SingleChoice(title: 'Black'),
              ],
              onSelected: (value) => setState(() => _color = value),
            ),
          ),
          _section(
            _StockCard(label: _definition.stockLabel),
          ),
        ];
    }
  }

  void _changeAddOn(String name, bool checked) {
    setState(() {
      if (checked) {
        _addOns.add(name);
      } else {
        _addOns.remove(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveProduct = widget.catalogProduct;
    final liveBranchId = widget.branchId;
    final hasLiveConfiguration = liveProduct != null &&
        (liveProduct.variants.isNotEmpty ||
            liveProduct.optionGroups.isNotEmpty);
    final editingServerConfiguration = widget.editingItem?.variantId != null ||
        (widget.editingItem?.optionValueIds.isNotEmpty ?? false);

    // Keep catalog/product identity and branch pricing linked to the API, but
    // preserve the complete customer demo configurator when the linked
    // catalog product does not expose variants/options. Products that expose
    // live configuration keep the API-authoritative configurator.
    if (CustomerCatalogStore.instance.usesApi &&
        liveProduct != null &&
        liveBranchId != null &&
        (hasLiveConfiguration || editingServerConfiguration)) {
      return LiveProductDetailScreen(
        branchId: liveBranchId,
        branchName: widget.branchName,
        serviceType: widget.serviceType,
        summary: liveProduct,
        editingItem: widget.editingItem,
      );
    }

    final shortBranch = widget.branchName.replaceFirst('Getin ', '');

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: CustomerFavoritesStore.instance,
                      builder: (context, _) {
                        final isFavorite =
                            CustomerFavoritesStore.instance.containsProduct(
                          serverProductId: widget.catalogProduct?.id ??
                              widget.editingItem?.productId,
                          name: widget.name,
                        );
                        return _HeroSection(
                          image: widget.image,
                          name: widget.name,
                          description: widget.description,
                          price: widget.price,
                          branchName: shortBranch,
                          isFavorite: isFavorite,
                          badge: _definition.badge,
                          productType: _type,
                          onFavorite: _toggleFavorite,
                          onShare: _shareProduct,
                        );
                      },
                    ),
                  ),
                  ..._configurationSlivers(),
                  if (_type != ProductType.merchandise)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 22, 16, 0),
                        child: _OftenOrderedWith(),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                      child: ProductReviewPreviewCard(
                        productName: widget.name,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                      child: _ProductInformation(
                        productType: _type,
                        description: widget.description,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Builder(
              builder: (context) {
                final currentItem = _currentCartItem();
                final viewingCart = widget.editingItem == null &&
                    _matchesLastAdded(currentItem);

                return _StickyCartBar(
                  quantity: _quantity,
                  enabled: _requiredComplete,
                  total: _money(_total),
                  primaryLabel: widget.editingItem != null
                      ? 'Update Cart'
                      : viewingCart
                          ? 'View Cart'
                          : 'Add to Cart',
                  onDecrease: () {
                    if (_quantity <= 1) return;
                    setState(() => _quantity -= 1);
                  },
                  onIncrease: () => setState(() => _quantity += 1),
                  onPrimary: viewingCart ? _openCart : _saveToCart,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchandiseGallery extends StatelessWidget {
  final String image;

  const _MerchandiseGallery({required this.image});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Product gallery',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '1 image available',
                style: TextStyle(color: AppColors.muted, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 210,
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: _ProductRemoteAwareImage(image: image, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          const Text(
            'Swipe to explore available product images.',
            style:
                TextStyle(color: AppColors.muted, fontSize: 9.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final String label;

  const _StockCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.inventory_2_outlined, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final String image;
  final String name;
  final String description;
  final String price;
  final String branchName;
  final bool isFavorite;
  final String? badge;
  final ProductType productType;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  const _HeroSection({
    required this.image,
    required this.name,
    required this.description,
    required this.price,
    required this.branchName,
    required this.isFavorite,
    required this.badge,
    required this.productType,
    required this.onFavorite,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final baseEarnStars = RewardEarningPolicy.starsForPrice(
      price,
      isMember: false,
    );
    final memberEarnStars = RewardEarningPolicy.starsForPrice(
      price,
      isMember: true,
    );

    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 320,
              width: double.infinity,
              color: Colors.white,
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _ProductRemoteAwareImage(
                  image: image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 14,
              child: _RoundIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              top: 12,
              right: 60,
              child: _RoundIconButton(
                icon: isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                onTap: onFavorite,
              ),
            ),
            Positioned(
              top: 12,
              right: 14,
              child: _RoundIconButton(
                icon: Icons.share_outlined,
                onTap: onShare,
              ),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            16,
            17,
            16,
            16,
          ),
          color: AppColors.cream,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.45,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badge == null ? Colors.white : AppColors.beige,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      badge ?? productType.label.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.beige,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Member Price',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.beige.withOpacity(0.34),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFD2A64A),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            CustomerMembershipStore.instance.isActive
                                ? 'Earn $memberEarnStars Stars · 1.5× Member rate'
                                : 'Earn $baseEarnStars Stars · Members earn $memberEarnStars',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (RewardEarningPolicy.earnsStamp(productType)) ...[
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(
                            Icons.local_cafe_rounded,
                            color: AppColors.green,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'This eligible drink earns 1 Getin stamp · collect 7 for a free drink',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Getin $branchName',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '0.4 km away · Open now',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F2E9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Available',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: AppColors.green,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _QuickChoices extends StatelessWidget {
  final VoidCallback onPopular;
  final VoidCallback onClassic;

  const _QuickChoices({
    required this.onPopular,
    required this.onClassic,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Try these quick choices',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Ready to go',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Popular combinations you can use instantly.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickChoiceCard(
                  label: 'MOST POPULAR',
                  lines: const [
                    'Large',
                    'Iced',
                    'Coconut Milk',
                    'Regular Sweetness',
                  ],
                  onTap: onPopular,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _QuickChoiceCard(
                  label: 'CLASSIC',
                  lines: const [
                    'Regular',
                    'Iced',
                    'Low Fat Milk',
                    'No Sugar',
                  ],
                  onTap: onClassic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickChoiceCard extends StatelessWidget {
  final String label;
  final List<String> lines;
  final VoidCallback onTap;

  const _QuickChoiceCard({
    required this.label,
    required this.lines,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: AppColors.beige,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 9),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 9.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.beige,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Use this',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequiredSingleChoiceSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? selected;
  final List<_SingleChoice> choices;
  final ValueChanged<String> onSelected;

  const _RequiredSingleChoiceSection({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.choices,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _ChoiceSection(
      title: title,
      subtitle: subtitle,
      badge: 'Required',
      child: _ChoiceWrap(
        selected: selected,
        choices: choices,
        onSelected: onSelected,
      ),
    );
  }
}

class _OptionalSingleChoiceSection extends StatelessWidget {
  final String title;
  final String selected;
  final List<_SingleChoice> choices;
  final ValueChanged<String> onSelected;

  const _OptionalSingleChoiceSection({
    required this.title,
    required this.selected,
    required this.choices,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _ChoiceSection(
      title: title,
      badge: 'Optional',
      child: _ChoiceWrap(
        selected: selected,
        choices: choices,
        onSelected: onSelected,
      ),
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String badge;
  final Widget child;

  const _ChoiceSection({
    required this.title,
    required this.badge,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color:
                      badge == 'Required' ? AppColors.green : AppColors.beige,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color:
                        badge == 'Required' ? AppColors.beige : AppColors.green,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 9.5,
              ),
            ),
          ],
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  final String? selected;
  final List<_SingleChoice> choices;
  final ValueChanged<String> onSelected;

  const _ChoiceWrap({
    required this.selected,
    required this.choices,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final compact = constraints.maxWidth < 340;
        final width =
            compact ? constraints.maxWidth : (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: choices
              .map(
                (choice) => SizedBox(
                  width: width,
                  child: _ChoiceTile(
                    choice: choice,
                    selected: selected == choice.title,
                    onTap: () => onSelected(choice.title),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final _SingleChoice choice;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.beige.withOpacity(0.33) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: selected ? AppColors.green : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.green : AppColors.muted,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.beige,
                        size: 12,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (choice.icon != null) ...[
                          Icon(
                            choice.icon,
                            color: AppColors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            choice.title,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (choice.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        choice.subtitle!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                    if (choice.surcharge != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        choice.surcharge!,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
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

class _AddOnsSection extends StatelessWidget {
  final Set<String> selected;
  final List<_AddOn> items;
  final void Function(String name, bool checked) onChanged;

  const _AddOnsSection({
    required this.selected,
    required this.onChanged,
    this.items = const [
      _AddOn('Vanilla', '+ EGP 20'),
      _AddOn('Caramel', '+ EGP 20'),
      _AddOn('Hazelnut', '+ EGP 20'),
      _AddOn('Chocolate Drizzle', '+ EGP 20'),
      _AddOn('Extra Espresso', '+ EGP 25'),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Add-ons',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Optional',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ...items.asMap().entries.map(
            (entry) {
              final item = entry.value;
              final checked = selected.contains(item.name);

              return Column(
                children: [
                  InkWell(
                    onTap: () => onChanged(
                      item.name,
                      !checked,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: AppColors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            item.price,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 9.5,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: checked
                                  ? AppColors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    checked ? AppColors.green : AppColors.muted,
                              ),
                            ),
                            child: checked
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: AppColors.beige,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (entry.key != items.length - 1)
                    const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OftenOrderedWith extends StatelessWidget {
  const _OftenOrderedWith();

  static const items = <_PairingItem>[
    _PairingItem(
      name: 'Butter Croissant',
      price: 'EGP 45',
      image: 'assets/images/products/butter_croissant.png',
    ),
    _PairingItem(
      name: 'Blueberry Muffin',
      price: 'EGP 60',
      image: 'assets/images/products/blueberry_muffin.png',
    ),
    _PairingItem(
      name: 'Turkey & Cheese',
      price: 'EGP 95',
      image: 'assets/images/products/turkey_cheese_sandwich.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Often Ordered With',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Complete your Getin moment.',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(height: 11),
        SizedBox(
          height: MediaQuery.sizeOf(context).width < 380 ? 188 : 178,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final item = items[index];

              return Container(
                width: 126,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        item.image,
                        width: double.infinity,
                        height: 77,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.price,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          width: 25,
                          height: 25,
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.beige,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductInformation extends StatelessWidget {
  final ProductType productType;
  final String description;

  const _ProductInformation({
    required this.productType,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _InfoTile(
        title: 'Description',
        preview: description,
      ),
    ];

    switch (productType) {
      case ProductType.drink:
        tiles.addAll(const [
          _InfoTile(
            title: 'Ingredients',
            preview:
                'Espresso and beverage ingredients. Customizations may add milk, syrups or other ingredients.',
          ),
          _InfoTile(
            title: 'Allergens',
            preview:
                'Milk and add-ons may contain dairy, nuts or other allergens.',
          ),
          _InfoTile(
            title: 'Nutrition',
            preview: 'Nutrition varies by size and customization.',
            last: true,
          ),
        ]);
        break;
      case ProductType.refreshment:
        tiles.addAll(const [
          _InfoTile(
            title: 'Ingredients',
            preview:
                'Fruit and botanical beverage ingredients. Add-ons may change the final recipe.',
          ),
          _InfoTile(
            title: 'Allergens',
            preview: 'Check selected add-ons for allergen information.',
          ),
          _InfoTile(
            title: 'Nutrition',
            preview: 'Nutrition varies by size, sweetness and add-ons.',
            last: true,
          ),
        ]);
        break;
      case ProductType.food:
        tiles.addAll(const [
          _InfoTile(
            title: 'Ingredients',
            preview:
                'Prepared food ingredients vary by product and selected extras.',
          ),
          _InfoTile(
            title: 'Allergens',
            preview:
                'May contain gluten, dairy, eggs, nuts or other allergens.',
          ),
          _InfoTile(
            title: 'Preparation',
            preview: 'Choose warming, variant and sauce where available.',
            last: true,
          ),
        ]);
        break;
      case ProductType.bakery:
        tiles.addAll(const [
          _InfoTile(
            title: 'Ingredients',
            preview:
                'Bakery ingredients vary by item and selected finish/add-ons.',
          ),
          _InfoTile(
            title: 'Allergens',
            preview:
                'May contain gluten, dairy, eggs, nuts or other allergens.',
          ),
          _InfoTile(
            title: 'Preparation',
            preview: 'Choose warm or not warmed when available.',
            last: true,
          ),
        ]);
        break;
      case ProductType.merchandise:
        tiles.addAll(const [
          _InfoTile(
            title: 'Materials & care',
            preview:
                'Demo merchandise details. Final materials and care guidance will come from product data.',
          ),
          _InfoTile(
            title: 'Availability',
            preview: 'Availability can vary by branch.',
            last: true,
          ),
        ]);
        break;
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Information',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          ...tiles,
        ],
      ),
    );
  }
}

class _InfoTile extends StatefulWidget {
  final String title;
  final String preview;
  final bool last;

  const _InfoTile({
    required this.title,
    required this.preview,
    this.last = false,
  });

  @override
  State<_InfoTile> createState() => _InfoTileState();
}

class _InfoTileState extends State<_InfoTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() => _expanded = !_expanded);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.chevron_right_rounded,
                  color: AppColors.green,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(
              right: 24,
              bottom: 10,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.preview,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9.5,
                  height: 1.35,
                ),
              ),
            ),
          ),
        if (!widget.last)
          const Divider(
            height: 1,
            color: AppColors.border,
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _StickyCartBar extends StatelessWidget {
  final int quantity;
  final bool enabled;
  final String total;
  final String primaryLabel;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onPrimary;

  const _StickyCartBar({
    required this.quantity,
    required this.enabled,
    required this.total,
    required this.primaryLabel,
    required this.onDecrease,
    required this.onIncrease,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        9,
        14,
        10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!enabled)
              const Padding(
                padding: EdgeInsets.only(bottom: 7),
                child: Text(
                  'Select required options to add item',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                  ),
                ),
              ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              primaryLabel,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            total,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
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

class _SingleChoice {
  final String title;
  final String? subtitle;
  final String? surcharge;
  final IconData? icon;

  const _SingleChoice({
    required this.title,
    this.subtitle,
    this.surcharge,
    this.icon,
  });
}

class _AddOn {
  final String name;
  final String price;

  const _AddOn(
    this.name,
    this.price,
  );
}

class _PairingItem {
  final String name;
  final String price;
  final String image;

  const _PairingItem({
    required this.name,
    required this.price,
    required this.image,
  });
}

class _ProductRemoteAwareImage extends StatelessWidget {
  final String image;
  final BoxFit fit;

  const _ProductRemoteAwareImage({required this.image, required this.fit});

  @override
  Widget build(BuildContext context) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        fit: fit,
        errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.cream),
      );
    }
    if (image.trim().isEmpty) return const ColoredBox(color: AppColors.cream);
    return Image.asset(image, fit: fit);
  }
}
