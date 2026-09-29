import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';

class DriverTrackingSnapshot {
  final double latitude;
  final double longitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final int etaMinutes;
  final double distanceKm;
  final DateTime updatedAt;
  final List<LatLng> routePoints;

  const DriverTrackingSnapshot({
    required this.latitude,
    required this.longitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.etaMinutes,
    required this.distanceKm,
    required this.updatedAt,
    required this.routePoints,
  });
}

class LiveDriverTrackingCard extends StatelessWidget {
  final String orderId;
  final double? destinationLatitude;
  final double? destinationLongitude;

  /// Later, the real API / websocket layer should provide this stream.
  /// When null, production mode shows a safe "waiting for GPS" state.
  final Stream<DriverTrackingSnapshot>? liveStream;

  const LiveDriverTrackingCard({
    super.key,
    required this.orderId,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.liveStream,
  });

  static const bool _previewMode = bool.fromEnvironment(
    'GETIN_TRACKING_PREVIEW',
    defaultValue: false,
  );

  @override
  Widget build(BuildContext context) {
    if (destinationLatitude == null || destinationLongitude == null) {
      return const _TrackingUnavailableCard(
        message:
            'Delivery destination coordinates are not available for this order.',
      );
    }

    final stream = liveStream ??
        (_previewMode
            ? _PreviewDriverTracker(
                destination: LatLng(
                  destinationLatitude!,
                  destinationLongitude!,
                ),
              ).stream
            : null);

    if (stream == null) {
      return const _TrackingUnavailableCard(
        message:
            'Waiting for live driver GPS. Tracking appears here when the assigned driver starts the delivery.',
      );
    }

    return StreamBuilder<DriverTrackingSnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _TrackingUnavailableCard(
            loading: true,
            message: 'Connecting to driver location…',
          );
        }

        final tracking = snapshot.data!;
        final driver = LatLng(
          tracking.latitude,
          tracking.longitude,
        );
        final destination = LatLng(
          tracking.destinationLatitude,
          tracking.destinationLongitude,
        );

        final midpoint = LatLng(
          (driver.latitude + destination.latitude) / 2,
          (driver.longitude + destination.longitude) / 2,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  14,
                  13,
                  14,
                  12,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Live delivery tracking',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _previewMode
                            ? AppColors.beige
                            : const Color(0xFFE9F3ED),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        _previewMode ? 'DEV PREVIEW' : 'LIVE',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 210,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: midpoint,
                    initialZoom: 14.2,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.getincoffee.getin_coffee',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: tracking.routePoints,
                          strokeWidth: 4,
                          color: AppColors.green,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: destination,
                          width: 44,
                          height: 44,
                          child: const _TrackingMarker(
                            icon: Icons.home_rounded,
                            background: AppColors.beige,
                            foreground: AppColors.green,
                          ),
                        ),
                        Marker(
                          point: driver,
                          width: 50,
                          height: 50,
                          child: const _TrackingMarker(
                            icon: Icons.delivery_dining_rounded,
                            background: AppColors.green,
                            foreground: AppColors.beige,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  14,
                  12,
                  14,
                  14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TrackingMetric(
                        label: 'Estimated arrival',
                        value: tracking.etaMinutes <= 1
                            ? 'Arriving'
                            : '${tracking.etaMinutes} min',
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.border,
                    ),
                    Expanded(
                      child: _TrackingMetric(
                        label: 'Driver distance',
                        value: '${tracking.distanceKm.toStringAsFixed(1)} km',
                        icon: Icons.route_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              if (_previewMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    9,
                    14,
                    10,
                  ),
                  color: AppColors.beige.withOpacity(0.35),
                  child: const Text(
                    'Development preview only. Real tracking will use GPS from the assigned Driver App and route ETA from the backend.',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TrackingMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TrackingMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppColors.green,
          size: 18,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 8.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackingMarker extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;

  const _TrackingMarker({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: foreground,
        size: 24,
      ),
    );
  }
}

class _TrackingUnavailableCard extends StatelessWidget {
  final String message;
  final bool loading;

  const _TrackingUnavailableCard({
    required this.message,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.beige,
              shape: BoxShape.circle,
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.green,
                    ),
                  )
                : const Icon(
                    Icons.location_searching_rounded,
                    color: AppColors.green,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 10.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewDriverTracker {
  final LatLng destination;

  const _PreviewDriverTracker({
    required this.destination,
  });

  Stream<DriverTrackingSnapshot> get stream async* {
    const secondsPerTrip = 120;
    var tick = 0;

    while (true) {
      final progress = (tick % secondsPerTrip) / secondsPerTrip;

      // Preview starts ~1.7 km southwest of the destination.
      final start = LatLng(
        destination.latitude - 0.0105,
        destination.longitude - 0.0135,
      );

      final driver = LatLng(
        _lerp(
          start.latitude,
          destination.latitude,
          progress,
        ),
        _lerp(
          start.longitude,
          destination.longitude,
          progress,
        ),
      );

      final remainingKm = _distanceKm(
        driver,
        destination,
      );

      final etaMinutes = math.max(1, (remainingKm / 0.42).ceil());

      yield DriverTrackingSnapshot(
        latitude: driver.latitude,
        longitude: driver.longitude,
        destinationLatitude: destination.latitude,
        destinationLongitude: destination.longitude,
        etaMinutes: etaMinutes,
        distanceKm: remainingKm,
        updatedAt: DateTime.now(),
        routePoints: [
          driver,
          destination,
        ],
      );

      tick += 4;
      await Future<void>.delayed(
        const Duration(seconds: 4),
      );
    }
  }

  static double _lerp(
    double a,
    double b,
    double t,
  ) {
    return a + (b - a) * t;
  }

  static double _distanceKm(
    LatLng a,
    LatLng b,
  ) {
    const earthRadius = 6371.0;

    final dLat = _rad(
      b.latitude - a.latitude,
    );
    final dLon = _rad(
      b.longitude - a.longitude,
    );

    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    return earthRadius *
        2 *
        math.atan2(
          math.sqrt(h),
          math.sqrt(1 - h),
        );
  }

  static double _rad(double value) {
    return value * math.pi / 180;
  }
}
