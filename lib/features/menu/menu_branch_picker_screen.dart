import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../location/models/branch.dart';
import '../location/services/branch_service.dart';
import '../location/widgets/branch_image.dart';

class MenuBranchSelection {
  final Branch branch;
  final String serviceType;

  const MenuBranchSelection({
    required this.branch,
    required this.serviceType,
  });
}

class MenuBranchPickerScreen extends StatefulWidget {
  final Branch currentBranch;
  final String currentServiceType;
  final double userLatitude;
  final double userLongitude;

  const MenuBranchPickerScreen({
    super.key,
    required this.currentBranch,
    required this.currentServiceType,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  State<MenuBranchPickerScreen> createState() => _MenuBranchPickerScreenState();
}

class _MenuBranchPickerScreenState extends State<MenuBranchPickerScreen> {
  late String _serviceType;

  @override
  void initState() {
    super.initState();
    _serviceType = widget.currentServiceType;
  }

  List<BranchDistance> get _nearbyBranches {
    return BranchService().nearbyBranches(
      latitude: widget.userLatitude,
      longitude: widget.userLongitude,
      serviceType: _serviceType,
      countryCode: widget.currentBranch.countryCode,
    );
  }

  void _select(Branch branch) {
    Navigator.of(context).pop(
      MenuBranchSelection(
        branch: branch,
        serviceType: _serviceType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nearby = _nearbyBranches;
    final userPoint = LatLng(
      widget.userLatitude,
      widget.userLongitude,
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Choose a nearby branch',
          style: TextStyle(
            color: AppColors.green,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: _ServiceSelector(
                value: _serviceType,
                onChanged: (value) {
                  if (_serviceType == value) return;
                  setState(() => _serviceType = value);
                },
              ),
            ),
            SizedBox(
              height: 226,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: userPoint,
                        initialZoom: 12.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.getincoffee.getin_coffee',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: userPoint,
                              width: 42,
                              height: 42,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.green,
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  color: AppColors.green,
                                  size: 19,
                                ),
                              ),
                            ),
                            for (final item in nearby)
                              Marker(
                                point: LatLng(
                                  item.branch.latitude,
                                  item.branch.longitude,
                                ),
                                width: 52,
                                height: 52,
                                child: GestureDetector(
                                  onTap: () => _select(item.branch),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.green,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 9,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.local_cafe_rounded,
                                      color: AppColors.beige,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            color: AppColors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${nearby.length} nearby Getin branches available for ${_serviceType == 'pickup' ? 'pickup' : 'delivery'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.green,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nearby branches',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Text(
                    'Nearest first',
                    style: TextStyle(
                      color: AppColors.muted.withOpacity(0.9),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: nearby.isEmpty
                  ? const _NoBranchesState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      itemCount: nearby.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = nearby[index];
                        final current =
                            item.branch.id == widget.currentBranch.id &&
                                _serviceType == widget.currentServiceType;

                        return _BranchCard(
                          item: item,
                          serviceType: _serviceType,
                          current: current,
                          onTap: () => _select(item.branch),
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

class _ServiceSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ServiceSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ServiceButton(
              label: 'Delivery',
              icon: Icons.delivery_dining_rounded,
              selected: value == 'delivery',
              onTap: () => onChanged('delivery'),
            ),
          ),
          Expanded(
            child: _ServiceButton(
              label: 'Pickup',
              icon: Icons.shopping_bag_outlined,
              selected: value == 'pickup',
              onTap: () => onChanged('pickup'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.green : Colors.transparent,
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
                size: 19,
                color: selected ? AppColors.beige : AppColors.green,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.beige : AppColors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final BranchDistance item;
  final String serviceType;
  final bool current;
  final VoidCallback onTap;

  const _BranchCard({
    required this.item,
    required this.serviceType,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final branch = item.branch;
    final availability = branch.deliveryEnabled && branch.pickupEnabled
        ? 'Delivery & pickup'
        : branch.deliveryEnabled
            ? 'Delivery'
            : 'Pickup';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: current ? AppColors.green : AppColors.border,
              width: current ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              BranchImage(
                branch: branch,
                width: 58,
                height: 58,
                borderRadius: BorderRadius.circular(15),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            branch.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (current)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'CURRENT',
                              style: TextStyle(
                                color: AppColors.beige,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.distanceKm.toStringAsFixed(1)} km away • $availability',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      serviceType == 'pickup'
                          ? 'Choose this branch to browse its pickup menu.'
                          : 'Choose this branch to browse its delivery menu.',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoBranchesState extends StatelessWidget {
  const _NoBranchesState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'No nearby branches are available for this service right now.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
