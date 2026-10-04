import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../cart/cart_controller.dart';
import '../../cart/cart_screen.dart';
import '../../location/models/branch.dart';

class HomeHeader extends StatelessWidget {
  final Branch branch;
  final double distanceKm;
  final String serviceType;
  final int stars;
  final VoidCallback onNotification;
  final VoidCallback onRewards;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final ValueChanged<String> onServiceChanged;

  const HomeHeader({
    super.key,
    required this.branch,
    required this.distanceKm,
    required this.serviceType,
    required this.stars,
    required this.onNotification,
    required this.onRewards,
    required this.onSearch,
    required this.onFilter,
    required this.onServiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final branchContext = <String>[
      if (branch.city?.trim().isNotEmpty == true) branch.city!.trim(),
      if (branch.countryCode?.trim().isNotEmpty == true)
        branch.countryCode!.trim().toUpperCase(),
      if (branch.currency?.trim().isNotEmpty == true)
        branch.currency!.trim().toUpperCase(),
      '${distanceKm.toStringAsFixed(1)} km',
    ].join(' · ');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Good morning',
                  style: TextStyle(
                    color: AppColors.beige,
                    fontSize: 27,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              _HeaderAction(
                onTap: onNotification,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.beige,
                    ),
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF07A77),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: CartController.instance,
                builder: (context, _) {
                  final cart = CartController.instance;
                  if (cart.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Row(
                    children: [
                      const SizedBox(width: 8),
                      _HeaderAction(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CartScreen(),
                            ),
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              color: AppColors.beige,
                            ),
                            Positioned(
                              right: -8,
                              top: -8,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.gold,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${cart.itemCount}',
                                  style: const TextStyle(
                                    color: AppColors.greenDark,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              _HeaderAction(
                onTap: onRewards,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.gold,
                      size: 21,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$stars',
                      style: const TextStyle(
                        color: AppColors.beige,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.beige,
                size: 19,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      branchContext,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.beige,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.beige,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Delivery',
                    icon: Icons.delivery_dining_rounded,
                    selected: serviceType == 'delivery',
                    onTap: () => onServiceChanged('delivery'),
                  ),
                ),
                Expanded(
                  child: _ModeButton(
                    label: 'Pickup',
                    icon: Icons.shopping_bag_outlined,
                    selected: serviceType == 'pickup',
                    onTap: () => onServiceChanged('pickup'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onSearch,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.search_rounded, color: AppColors.green),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Search for drinks, food, or more...',
                        style:
                            TextStyle(color: AppColors.muted, fontSize: 13.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        tooltip: 'Filter products',
                        onPressed: onFilter,
                        icon: const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.cream,
                          child: Icon(Icons.tune_rounded,
                              color: AppColors.green, size: 19),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HeaderAction({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.beige : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.green : AppColors.beige,
                size: 20,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.green : AppColors.beige,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
