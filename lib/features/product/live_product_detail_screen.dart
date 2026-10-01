import 'package:flutter/material.dart';

import '../../core/catalog/customer_catalog_models.dart';
import '../../core/catalog/customer_catalog_store.dart';
import '../../core/theme/app_colors.dart';
import '../cart/cart_controller.dart';

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
  Object? _error;
  bool _loading = true;

  CatalogProduct get _displayProduct => _product ?? widget.summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
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
      setState(() {
        _product = product;
        _availability = availability;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _displayProduct;
    final availability = _availability;
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
      ),
      body: RefreshIndicator(
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
              price: product.displayPrice,
              branchName: widget.branchName,
            ),
            const SizedBox(height: 14),
            if (_loading)
              const _LiveProductStatusCard(
                icon: Icons.sync_rounded,
                title: 'Loading live configuration',
                body: 'Checking this branch for current options and stock.',
              )
            else if (_error != null)
              _LiveProductErrorCard(onRetry: _load)
            else
              _LiveProductStatusCard(
                icon: availability?.available == true
                    ? Icons.check_circle_outline_rounded
                    : Icons.inventory_2_outlined,
                title: availability?.available == true
                    ? 'Available at this branch'
                    : 'Currently unavailable',
                body: availability?.available == true
                    ? 'Live product data is loaded. Configuration follows the server contract.'
                    : 'This branch reports ${availability?.status ?? 'unavailable'}.',
              ),
            if (!_loading && _error == null) ...[
              const SizedBox(height: 14),
              const _LiveProductStatusCard(
                icon: Icons.tune_rounded,
                title: 'Live configuration ready',
                body: 'Server-driven choices and authoritative pricing are loaded in the next Phase 15 task.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LiveProductHero extends StatelessWidget {
  final String image;
  final String name;
  final String description;
  final String price;
  final String branchName;

  const _LiveProductHero({
    required this.image,
    required this.name,
    required this.description,
    required this.price,
    required this.branchName,
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
                    Text(
                      price,
                      style: const TextStyle(
                        color: AppColors.green,
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

class _LiveProductStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _LiveProductStatusCard({
    required this.icon,
    required this.title,
    required this.body,
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
            'Could not load live product details',
            style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'No demo configuration will be substituted in API mode.',
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
