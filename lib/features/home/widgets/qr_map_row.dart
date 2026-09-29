import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../location/models/branch.dart';

class QrMapRow extends StatelessWidget {
  final Branch branch;
  final double distanceKm;
  final VoidCallback onScanQr;
  final VoidCallback onOpenMap;
  final VoidCallback onChangeBranch;

  const QrMapRow({
    super.key,
    required this.branch,
    required this.distanceKm,
    required this.onScanQr,
    required this.onOpenMap,
    required this.onChangeBranch,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;

        if (compact) {
          return Column(
            children: [
              SizedBox(
                height: 88,
                child: _QrCard(onTap: onScanQr),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 116,
                child: _MapCard(
                  branch: branch,
                  distanceKm: distanceKm,
                  onOpenMap: onOpenMap,
                  onChangeBranch: onChangeBranch,
                ),
              ),
            ],
          );
        }

        return SizedBox(
          height: 116,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 48,
                child: _QrCard(onTap: onScanQr),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 52,
                child: _MapCard(
                  branch: branch,
                  distanceKm: distanceKm,
                  onOpenMap: onOpenMap,
                  onChangeBranch: onChangeBranch,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QrCard extends StatelessWidget {
  final VoidCallback onTap;

  const _QrCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.green,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFF29453E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.beige,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Scan QR',
                      style: TextStyle(
                        color: AppColors.beige,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pay at branch · Earn rewards',
                      softWrap: true,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9.1,
                        height: 1.18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.beige,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final Branch branch;
  final double distanceKm;
  final VoidCallback onOpenMap;
  final VoidCallback onChangeBranch;

  const _MapCard({
    required this.branch,
    required this.distanceKm,
    required this.onOpenMap,
    required this.onChangeBranch,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(branch.latitude, branch.longitude);
    final shortName = branch.name.replaceFirst('Getin ', '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            flex: 48,
            child: InkWell(
              onTap: onOpenMap,
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 14.2,
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
                          point: point,
                          width: 36,
                          height: 36,
                          child: const CircleAvatar(
                            backgroundColor: AppColors.green,
                            child: Icon(
                              Icons.location_on_rounded,
                              color: AppColors.beige,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 52,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shortName,
                    softWrap: true,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${distanceKm.toStringAsFixed(1)} km away',
                    softWrap: true,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 9.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: OutlinedButton(
                      onPressed: onChangeBranch,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.green,
                        side: const BorderSide(color: AppColors.border),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 9.6,
                          fontWeight: FontWeight.w700,
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
    );
  }
}
