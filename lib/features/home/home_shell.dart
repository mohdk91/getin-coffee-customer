import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/catalog/customer_catalog_store.dart';
import '../../core/content/mobile_app_content_store.dart';
import '../../core/navigation/app_navigation_controller.dart';
import '../../core/theme/app_colors.dart';
import '../cart/cart_controller.dart';
import '../location/models/branch.dart';
import '../location/services/branch_service.dart';
import '../membership/membership_screen.dart';
import '../menu/menu_branch_picker_screen.dart';
import '../menu/menu_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  final Branch branch;
  final String serviceType;
  final double distanceKm;
  final double userLatitude;
  final double userLongitude;

  const HomeShell({
    super.key,
    required this.branch,
    required this.serviceType,
    required this.distanceKm,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late Branch _branch;
  late String _serviceType;

  bool _menuBranchConfirmed = false;
  bool _menuPickerOpen = false;

  @override
  void initState() {
    super.initState();
    _branch = widget.branch;
    _serviceType = widget.serviceType;
    AppNavigationController.instance.addListener(
      _handleNavigationRequest,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncCommerceContext());
    });
  }

  Future<void> _syncCommerceContext() async {
    try {
      await Future.wait<void>(<Future<void>>[
        CustomerCatalogStore.instance.refreshBranch(_branch.id),
        MobileAppContentStore.instance.refresh(
          branchId: _branch.id,
          market: _branch.countryCode,
          fulfillment: _serviceType,
        ),
      ]);
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Stores retain their last valid snapshots; screens expose their own
      // fallback/error UI instead of replacing live data with fake success.
    }
  }

  void _handleNavigationRequest() {
    final requested = AppNavigationController.instance.takeRequestedTab();

    if (requested == null) {
      return;
    }

    if (requested == 1) {
      _openMenu();
      return;
    }

    if (requested == _index) {
      return;
    }

    if (mounted) {
      setState(() => _index = requested);
    }
  }

  @override
  void dispose() {
    AppNavigationController.instance.removeListener(
      _handleNavigationRequest,
    );
    super.dispose();
  }

  void _changeService(String value) {
    if (_serviceType == value) return;

    final nearest = BranchService().nearest(
      latitude: widget.userLatitude,
      longitude: widget.userLongitude,
      serviceType: value,
    );

    setState(() {
      _serviceType = value;
      _menuBranchConfirmed = false;
      if (nearest != null) {
        _branch = nearest;
      }
    });
    unawaited(_syncCommerceContext());
  }

  Future<bool> _confirmContextChange(MenuBranchSelection selection) async {
    final branchChanged = selection.branch.id != _branch.id;
    final serviceChanged = selection.serviceType != _serviceType;

    if (!branchChanged && !serviceChanged) {
      return true;
    }

    final cart = CartController.instance;
    final cartWouldConflict = cart.isNotEmpty &&
        (cart.cartBranchName != selection.branch.name ||
            cart.cartServiceType != selection.serviceType);

    if (!cartWouldConflict) {
      return true;
    }

    final continueChange = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final targetMode =
            selection.serviceType == 'pickup' ? 'pickup' : 'delivery';

        return AlertDialog(
          title: const Text('Change branch?'),
          content: Text(
            'Your current cart belongs to ${cart.cartBranchName ?? 'another branch'}. '
            'Menu items, prices and availability can differ by branch. '
            'You can switch to ${selection.branch.name} for $targetMode without deleting the cart, '
            'but the existing cart will stay linked to its original branch until you replace it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep current branch'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.beige,
              ),
              child: const Text('Switch branch'),
            ),
          ],
        );
      },
    );

    return continueChange == true;
  }

  Future<void> _openMenu({bool forcePicker = false}) async {
    if (!mounted || _menuPickerOpen) {
      return;
    }

    if (_menuBranchConfirmed && !forcePicker) {
      if (_index != 1) {
        setState(() => _index = 1);
      }
      return;
    }

    _menuPickerOpen = true;

    final selection = await Navigator.of(context).push<MenuBranchSelection>(
      MaterialPageRoute(
        builder: (_) => MenuBranchPickerScreen(
          currentBranch: _branch,
          currentServiceType: _serviceType,
          userLatitude: widget.userLatitude,
          userLongitude: widget.userLongitude,
        ),
      ),
    );

    _menuPickerOpen = false;

    if (selection == null || !mounted) {
      return;
    }

    final canChange = await _confirmContextChange(selection);
    if (!canChange || !mounted) {
      return;
    }

    setState(() {
      _branch = selection.branch;
      _serviceType = selection.serviceType;
      _menuBranchConfirmed = true;
      _index = 1;
    });
    unawaited(_syncCommerceContext());
  }

  @override
  Widget build(BuildContext context) {
    CartController.instance.setOrderContext(
      branchId: _branch.id,
      branchName: _branch.name,
      serviceType: _serviceType,
      userLatitude: widget.userLatitude,
      userLongitude: widget.userLongitude,
    );

    final pages = [
      HomeScreen(
        branch: _branch,
        serviceType: _serviceType,
        userLatitude: widget.userLatitude,
        userLongitude: widget.userLongitude,
        onBranchChanged: (value) {
          setState(() {
            _branch = value;
            _menuBranchConfirmed = false;
          });
          unawaited(_syncCommerceContext());
        },
        onServiceChanged: _changeService,
      ),
      MenuScreen(
        branch: _branch,
        serviceType: _serviceType,
        onChangeBranch: () => _openMenu(forcePicker: true),
      ),
      OrdersScreen(
        branch: _branch,
      ),
      const MembershipScreen(),
      ProfileScreen(
        onOpenOrders: () {
          setState(() => _index = 2);
        },
        onOpenMembership: () {
          setState(() => _index = 3);
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: _GetinBottomNavigationBar(
        currentIndex: _index,
        onTap: (value) {
          if (value == 1) {
            _openMenu();
            return;
          }

          setState(() => _index = value);
        },
      ),
    );
  }
}

class _GetinBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GetinBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.local_cafe_outlined, Icons.local_cafe_rounded, 'Menu'),
    (Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Orders'),
    (
      Icons.workspace_premium_outlined,
      Icons.workspace_premium_rounded,
      'Membership',
    ),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black12,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(
              _items.length,
              (index) => Expanded(
                child: _GetinNavItem(
                  icon: _items[index].$1,
                  selectedIcon: _items[index].$2,
                  label: _items[index].$3,
                  selected: currentIndex == index,
                  onTap: () => onTap(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GetinNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GetinNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? 48 : 34,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? AppColors.beige : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Icon(
                selected ? selectedIcon : icon,
                color: selected ? AppColors.green : AppColors.muted,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 15,
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: selected ? AppColors.green : AppColors.muted,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
