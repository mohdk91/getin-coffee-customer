import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import 'models/branch.dart';

class BranchMapScreen extends StatelessWidget {
  final Branch branch;
  final double userLatitude;
  final double userLongitude;

  const BranchMapScreen({
    super.key,
    required this.branch,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  Widget build(BuildContext context) {
    final branchPoint = LatLng(branch.latitude, branch.longitude);
    final userPoint = LatLng(userLatitude, userLongitude);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(branch.name),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: branchPoint,
          initialZoom: 14.5,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.getincoffee.getin_coffee',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: branchPoint,
                width: 50,
                height: 50,
                child: const _MapMarker(
                  icon: Icons.local_cafe_rounded,
                  background: AppColors.green,
                  foreground: AppColors.beige,
                ),
              ),
              Marker(
                point: userPoint,
                width: 42,
                height: 42,
                child: const _MapMarker(
                  icon: Icons.person_pin_circle_rounded,
                  background: AppColors.beige,
                  foreground: AppColors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  final LatLng initialPoint;

  const MapPickerScreen({
    super.key,
    required this.initialPoint,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Choose on Map'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _selectedPoint,
                initialZoom: 14.0,
                onTap: (_, point) {
                  setState(() {
                    _selectedPoint = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.getincoffee.getin_coffee',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 54,
                      height: 54,
                      child: const _MapMarker(
                        icon: Icons.location_on_rounded,
                        background: AppColors.green,
                        foreground: AppColors.beige,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context, _selectedPoint);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Confirm Location',
                    style: TextStyle(fontWeight: FontWeight.w700),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;

  const _MapMarker({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: foreground, size: 25),
    );
  }
}
