import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../home/home_shell.dart';
import 'branch_map_screen.dart';
import 'models/branch.dart';
import 'services/branch_service.dart';
import 'services/location_service.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  static const _alexandriaPreview = LatLng(31.2357, 29.9553);

  final _locationService = LocationService();
  final _branchService = BranchService();
  final _mapController = MapController();

  String _serviceType = 'delivery';
  bool _loading = false;
  String? _error;
  LatLng _previewPoint = _alexandriaPreview;

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);

      _previewPoint = point;
      _mapController.move(point, 15.0);

      final branch = _branchService.nearest(
        latitude: point.latitude,
        longitude: point.longitude,
        serviceType: _serviceType,
      );

      if (!mounted) return;

      if (branch == null) {
        setState(() {
          _loading = false;
          _error = 'No Getin branch is currently available for this service.';
        });
        return;
      }

      _openHome(branch: branch, point: point);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _chooseOnMap() async {
    final selected = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialPoint: _previewPoint,
        ),
      ),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _previewPoint = selected;
      _error = null;
    });

    _mapController.move(selected, 15.0);

    final branch = _branchService.nearest(
      latitude: selected.latitude,
      longitude: selected.longitude,
      serviceType: _serviceType,
    );

    if (branch == null) {
      setState(() {
        _error = 'No Getin branch is currently available for this location.';
      });
      return;
    }

    _openHome(branch: branch, point: selected);
  }

  void _openHome({
    required Branch branch,
    required LatLng point,
  }) {
    final distance = _branchService.distanceKm(
      latitude: point.latitude,
      longitude: point.longitude,
      branch: branch,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeShell(
          branch: branch,
          serviceType: _serviceType,
          distanceKm: distance,
          userLatitude: point.latitude,
          userLongitude: point.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _previewPoint,
                        initialZoom: 13.5,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
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
                              point: _previewPoint,
                              width: 52,
                              height: 52,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.beige,
                                  size: 27,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    left: 18,
                    right: 18,
                    top: 18,
                    child: _MapTopCard(),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set Your Location',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose delivery or pickup, then use your current location or select a point on the map.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeButton(
                              label: 'Delivery',
                              icon: Icons.delivery_dining_rounded,
                              selected: _serviceType == 'delivery',
                              onTap: () {
                                setState(() {
                                  _serviceType = 'delivery';
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: _ModeButton(
                              label: 'Pickup',
                              icon: Icons.shopping_bag_outlined,
                              selected: _serviceType == 'pickup',
                              onTap: () {
                                setState(() {
                                  _serviceType = 'pickup';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _useCurrentLocation,
                        icon: const Icon(
                          Icons.my_location_rounded,
                        ),
                        label: Text(
                          _loading
                              ? 'Finding nearest Getin...'
                              : 'Use Current Location',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: AppColors.beige,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _chooseOnMap,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text(
                          'Choose on Map',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(
                            color: AppColors.green,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
    );
  }
}

class _MapTopCard extends StatelessWidget {
  const _MapTopCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.location_searching_rounded,
            color: AppColors.green,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Find the nearest Getin Coffee',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
      color: selected ? AppColors.green : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.beige : AppColors.green,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.beige : AppColors.green,
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
