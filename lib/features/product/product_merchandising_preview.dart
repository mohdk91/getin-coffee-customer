import 'package:flutter/material.dart';

import '../../core/catalog/customer_catalog_models.dart';
import '../../core/theme/app_colors.dart';

class GuestProductMerchandisingPreview extends StatefulWidget {
  final String currency;
  final String productName;
  final String? categoryName;

  const GuestProductMerchandisingPreview({
    super.key,
    required this.currency,
    required this.productName,
    this.categoryName,
  });

  @override
  State<GuestProductMerchandisingPreview> createState() =>
      _GuestProductMerchandisingPreviewState();
}

class _GuestProductMerchandisingPreviewState
    extends State<GuestProductMerchandisingPreview> {
  late String _variant;
  final Set<String> _addOns = <String>{};
  String _quickChoice = 'Classic';

  bool get _foodLike {
    final source = '${widget.categoryName ?? ''} ${widget.productName}'
        .trim()
        .toLowerCase();
    return source.contains('bakery') ||
        source.contains('food') ||
        source.contains('sandwich') ||
        source.contains('croissant') ||
        source.contains('muffin');
  }

  @override
  void initState() {
    super.initState();
    _variant = _foodLike ? 'Classic' : 'Regular';
  }

  List<_PreviewChoice> get _variants => _foodLike
      ? const <_PreviewChoice>[
          _PreviewChoice('Classic'),
          _PreviewChoice('Warmed'),
        ]
      : const <_PreviewChoice>[
          _PreviewChoice('Regular'),
          _PreviewChoice('Large', amount: 20),
        ];

  List<_PreviewChoice> get _extras => _foodLike
      ? const <_PreviewChoice>[
          _PreviewChoice('Butter', amount: 10),
          _PreviewChoice('Cream Cheese', amount: 15),
          _PreviewChoice('Extra Cheese', amount: 20),
        ]
      : const <_PreviewChoice>[
          _PreviewChoice('Extra Espresso', amount: 25),
          _PreviewChoice('Oat Milk', amount: 20),
          _PreviewChoice('Vanilla', amount: 15),
        ];

  List<_QuickPreset> get _presets => _foodLike
      ? const <_QuickPreset>[
          _QuickPreset(
            name: 'Classic',
            variant: 'Classic',
            addOns: <String>[],
            caption: 'Simple and ready to enjoy.',
          ),
          _QuickPreset(
            name: 'Warm & Ready',
            variant: 'Warmed',
            addOns: <String>['Butter'],
            caption: 'Warmed with a buttery finish.',
          ),
          _QuickPreset(
            name: 'Loaded',
            variant: 'Warmed',
            addOns: <String>['Extra Cheese'],
            caption: 'A richer choice for a bigger bite.',
          ),
        ]
      : const <_QuickPreset>[
          _QuickPreset(
            name: 'Classic',
            variant: 'Regular',
            addOns: <String>[],
            caption: 'Balanced and simple.',
          ),
          _QuickPreset(
            name: 'Most Popular',
            variant: 'Large',
            addOns: <String>['Oat Milk'],
            caption: 'Large with a smooth oat finish.',
          ),
          _QuickPreset(
            name: 'Extra Kick',
            variant: 'Regular',
            addOns: <String>['Extra Espresso'],
            caption: 'A stronger coffee-forward choice.',
          ),
        ];

  void _applyPreset(_QuickPreset preset) {
    setState(() {
      _quickChoice = preset.name;
      _variant = preset.variant;
      _addOns
        ..clear()
        ..addAll(preset.addOns);
    });
  }

  void _toggleExtra(String name) {
    setState(() {
      _quickChoice = 'Custom';
      if (_addOns.contains(name)) {
        _addOns.remove(name);
      } else {
        _addOns.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreviewSectionCard(
          title: 'Quick choice',
          subtitle: 'Pick a popular combination in one tap.',
          child: SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final preset = _presets[index];
                final selected = _quickChoice == preset.name;
                return _QuickPresetCard(
                  preset: preset,
                  selected: selected,
                  onTap: () => _applyPreset(preset),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        _PreviewSectionCard(
          title: 'Variant',
          subtitle: 'Choose the style you prefer.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _variants
                .map(
                  (choice) => _PreviewChip(
                    label: choice.name,
                    price: _price(choice.amount),
                    selected: _variant == choice.name,
                    onTap: () => setState(() {
                      _quickChoice = 'Custom';
                      _variant = choice.name;
                    }),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 14),
        _PreviewSectionCard(
          title: 'Add-ons',
          subtitle: 'Make it yours with a little extra.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _extras
                .map(
                  (choice) => _PreviewChip(
                    label: choice.name,
                    price: _price(choice.amount),
                    selected: _addOns.contains(choice.name),
                    onTap: () => _toggleExtra(choice.name),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }

  String? _price(double amount) {
    if (amount <= 0) return null;
    final normalized = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return '+ ${widget.currency} $normalized';
  }
}

class LiveOftenOrderedWith extends StatelessWidget {
  final List<CatalogProduct> products;
  final ValueChanged<CatalogProduct> onProductTap;

  const LiveOftenOrderedWith({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Often Ordered With',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Complete your GETIN moment.',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 11),
        SizedBox(
          height: 184,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final product = products[index];
              return _PairingCard(
                product: product,
                onTap: () => onProductTap(product),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PreviewSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PreviewSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

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
          Text(
            title,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _QuickPresetCard extends StatelessWidget {
  final _QuickPreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _QuickPresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.beige.withOpacity(0.32) : AppColors.cream,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 148,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.green,
                      size: 17,
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                preset.caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  height: 1.25,
                ),
              ),
              const Spacer(),
              const Text(
                'Use this',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final String label;
  final String? price;
  final bool selected;
  final VoidCallback onTap;

  const _PreviewChip({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.beige.withOpacity(0.28) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
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
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: selected ? AppColors.green : AppColors.muted,
              ),
              const SizedBox(width: 7),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (price != null)
                    Text(
                      price!,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PairingCard extends StatelessWidget {
  final CatalogProduct product;
  final VoidCallback onTap;

  const _PairingCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = product.imageUrl ??
        (product.gallery.isNotEmpty ? product.gallery.first : '');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 132,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: double.infinity,
                  height: 82,
                  child: _RemoteAwareProductImage(image: image),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.displayPrice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.beige,
                      size: 17,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoteAwareProductImage extends StatelessWidget {
  final String image;

  const _RemoteAwareProductImage({required this.image});

  @override
  Widget build(BuildContext context) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ImageFallback(),
      );
    }
    if (image.trim().isEmpty) return const _ImageFallback();
    return Image.asset(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.cream,
      child: Center(
        child: Icon(
          Icons.local_cafe_outlined,
          color: AppColors.muted,
          size: 28,
        ),
      ),
    );
  }
}

class _PreviewChoice {
  final String name;
  final double amount;

  const _PreviewChoice(this.name, {this.amount = 0});
}

class _QuickPreset {
  final String name;
  final String variant;
  final List<String> addOns;
  final String caption;

  const _QuickPreset({
    required this.name,
    required this.variant,
    required this.addOns,
    required this.caption,
  });
}
