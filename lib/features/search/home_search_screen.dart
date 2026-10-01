import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/membership/customer_membership_store.dart';
import '../../core/products/product_type.dart';
import '../../core/rewards/reward_earning_policy.dart';
import '../../core/theme/app_colors.dart';
import '../location/models/branch.dart';
import '../product/product_detail_screen.dart';

class HomeSearchScreen extends StatefulWidget {
  final Branch branch;
  final String serviceType;
  final bool openFilters;

  const HomeSearchScreen({
    super.key,
    required this.branch,
    required this.serviceType,
    this.openFilters = false,
  });

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _query = '';
  String _category = 'All';
  bool _listening = false;

  static const _categories = <String>[
    'All',
    'Coffee',
    'Non-Coffee',
    'Food',
    'Bakery',
    'Refreshments',
    'Merchandise'
  ];

  static const _products = <_SearchProduct>[
    _SearchProduct(
        'Iced Latte',
        'Double espresso, fresh milk and ice.',
        'EGP 65',
        'Coffee',
        'assets/images/products/iced_latte.png',
        ProductType.drink),
    _SearchProduct(
        'Caramel Macchiato',
        'Espresso, milk and caramel finish.',
        'EGP 70',
        'Coffee',
        'assets/images/products/caramel_macchiato.png',
        ProductType.drink),
    _SearchProduct(
        'Iced Americano',
        'Espresso over ice with filtered water.',
        'EGP 55',
        'Coffee',
        'assets/images/products/iced_americano.png',
        ProductType.drink),
    _SearchProduct(
        'Pistachio Latte',
        'Creamy pistachio latte with a nutty finish.',
        'EGP 75',
        'Non-Coffee',
        'assets/images/products/pistachio_latte.png',
        ProductType.drink),
    _SearchProduct(
        'Turkey & Cheese Sandwich',
        'Turkey, cheese and fresh greens.',
        'EGP 95',
        'Food',
        'assets/images/products/turkey_cheese_sandwich.png',
        ProductType.food),
    _SearchProduct(
        'Butter Croissant',
        'Classic buttery flaky croissant.',
        'EGP 45',
        'Bakery',
        'assets/images/products/butter_croissant.png',
        ProductType.bakery),
    _SearchProduct(
        'Blueberry Muffin',
        'Soft muffin with blueberry pieces.',
        'EGP 60',
        'Bakery',
        'assets/images/products/blueberry_muffin.png',
        ProductType.bakery),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.openFilters) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFilters());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  List<_SearchProduct> get _filtered {
    final q = _query.trim().toLowerCase();
    return _products.where((product) {
      final categoryOk = _category == 'All' || product.category == _category;
      final searchOk = q.isEmpty ||
          product.name.toLowerCase().contains(q) ||
          product.description.toLowerCase().contains(q) ||
          product.category.toLowerCase().contains(q);
      return categoryOk && searchOk;
    }).toList();
  }

  Future<void> _listen() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Microphone search is unavailable. You can still type your search.')),
        );
      }
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        _controller.text = result.recognizedWords;
        _controller.selection =
            TextSelection.collapsed(offset: _controller.text.length);
        setState(() => _query = result.recognizedWords);
      },
    );
  }

  Future<void> _showFilters() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter products',
                  style: TextStyle(
                      color: AppColors.green,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories
                    .map((category) => ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) => Navigator.pop(context, category),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _category = selected);
  }

  void _openProduct(_SearchProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          name: product.name,
          description: product.description,
          image: product.image,
          price: product.price,
          branchName: widget.branch.name,
          serviceType: widget.serviceType,
          productType: product.type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filtered;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
        title:
            const Text('Search', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: TextField(
                controller: _controller,
                autofocus: !widget.openFilters,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search drinks, food, bakery or merchandise',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip:
                            _listening ? 'Stop listening' : 'Search by voice',
                        onPressed: _listen,
                        icon: Icon(_listening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded),
                      ),
                      IconButton(
                        tooltip: 'Filter',
                        onPressed: _showFilters,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            if (_category != 'All')
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                      label: Text(_category),
                      onDeleted: () => setState(() => _category = 'All')),
                ),
              ),
            Expanded(
              child: products.isEmpty
                  ? const Center(
                      child: Text('No products match this search.',
                          style: TextStyle(color: AppColors.muted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => _openProduct(product),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border)),
                              child: Row(
                                children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.asset(product.image,
                                          width: 76,
                                          height: 76,
                                          fit: BoxFit.cover)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(product.name,
                                            style: const TextStyle(
                                                color: AppColors.green,
                                                fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text(product.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 11)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              product.price,
                                              style: const TextStyle(
                                                color: AppColors.green,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFD2A64A),
                                              size: 13,
                                            ),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                '+${RewardEarningPolicy.starsForPrice(product.price, isMember: CustomerMembershipStore.instance.isActive, multiplier: CustomerMembershipStore.instance.earningMultiplier)} Stars${CustomerMembershipStore.instance.hasBonusMultiplier ? ' · ${CustomerMembershipStore.instance.earningMultiplierLabel}' : ''}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: AppColors.green,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ])),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: AppColors.green),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchProduct {
  final String name;
  final String description;
  final String price;
  final String category;
  final String image;
  final ProductType type;
  const _SearchProduct(this.name, this.description, this.price, this.category,
      this.image, this.type);
}
