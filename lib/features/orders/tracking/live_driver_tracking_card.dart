import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/auth/customer_auth_store.dart';
import '../../../core/orders/live_driver_tracking_controller.dart';
import '../../../core/orders/live_driver_tracking_repository.dart';
import '../../../core/theme/app_colors.dart';

class LiveDriverTrackingCard extends StatefulWidget {
  final int orderId;
  final VoidCallback? onMessageDriver;
  final LiveDriverTrackingRepository? repository;
  final Duration pollInterval;

  const LiveDriverTrackingCard({
    super.key,
    required this.orderId,
    this.onMessageDriver,
    this.repository,
    this.pollInterval = const Duration(seconds: 10),
  });

  @override
  State<LiveDriverTrackingCard> createState() => _LiveDriverTrackingCardState();
}

class _LiveDriverTrackingCardState extends State<LiveDriverTrackingCard>
    with WidgetsBindingObserver {
  late final LiveDriverTrackingController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final repository = widget.repository ??
        LiveDriverTrackingRepository(CustomerAuthStore.instance.context);
    _controller = LiveDriverTrackingController(
      repository: repository,
      orderId: widget.orderId,
      interval: widget.pollInterval,
    )..addListener(_onChanged);
    unawaited(_controller.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.resume());
      return;
    }
    _controller.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tracking = _controller.snapshot;
    if (tracking == null) {
      return _TrackingUnavailableCard(
        loading: _controller.loading,
        message: _controller.errorMessage ?? 'Connecting to GETIN driver GPS…',
        onRefresh: _controller.refresh,
      );
    }

    if (!tracking.hasPosition) {
      return _TrackingUnavailableCard(
        loading: _controller.loading,
        message: tracking.reason ?? _stateMessage(tracking.state),
        onRefresh: tracking.isTerminal ? null : _controller.refresh,
      );
    }

    final driver = LatLng(tracking.latitude!, tracking.longitude!);
    final destination = tracking.destinationLatitude != null &&
            tracking.destinationLongitude != null
        ? LatLng(
            tracking.destinationLatitude!,
            tracking.destinationLongitude!,
          )
        : null;
    final distanceKm = destination == null
        ? null
        : _distanceKm(
            driver,
            destination,
          );
    final center = destination == null
        ? driver
        : LatLng(
            (driver.latitude + destination.latitude) / 2,
            (driver.longitude + destination.longitude) / 2,
          );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
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
                _TrackingStateBadge(state: tracking.state),
              ],
            ),
          ),
          SizedBox(
            height: 210,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: destination == null ? 15 : 14.2,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.getincoffee.getin_coffee',
                ),
                if (destination != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [driver, destination],
                        strokeWidth: 3,
                        color: AppColors.green,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (destination != null)
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _TrackingMetric(
                  label: 'GPS updated',
                  value: _ageLabel(tracking.ageSeconds),
                  icon: Icons.schedule_rounded,
                ),
                _TrackingMetric(
                  label: 'GPS accuracy',
                  value: tracking.accuracyMeters == null
                      ? '—'
                      : '±${tracking.accuracyMeters!.toStringAsFixed(0)} m',
                  icon: Icons.gps_fixed_rounded,
                ),
                if (distanceKm != null)
                  _TrackingMetric(
                    label: 'Straight-line distance',
                    value: '${distanceKm.toStringAsFixed(1)} km',
                    icon: Icons.route_rounded,
                  ),
              ],
            ),
          ),
          if (tracking.state != 'live' || _controller.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
              color: AppColors.beige.withOpacity(0.35),
              child: Text(
                _controller.errorMessage ??
                    tracking.reason ??
                    _stateMessage(tracking.state),
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 9,
                  height: 1.3,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _controller.loading ? null : _controller.refresh,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Refresh GPS'),
                ),
                const Spacer(),
                if (widget.onMessageDriver != null &&
                    tracking.state != 'waiting_assignment')
                  TextButton.icon(
                    onPressed: widget.onMessageDriver,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                    label: const Text('Message driver'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _stateMessage(String state) => switch (state) {
        'waiting_assignment' => 'Waiting for GETIN to assign a driver.',
        'waiting_gps' => 'Waiting for the assigned driver to send GPS.',
        'stale' => 'The latest driver position is stale.',
        'inaccurate' => 'The latest driver position has low GPS accuracy.',
        'terminal' => 'Live driver tracking has ended for this delivery.',
        _ => 'Driver tracking is temporarily unavailable.',
      };

  static String _ageLabel(int? seconds) {
    if (seconds == null) return '—';
    if (seconds < 5) return 'Just now';
    if (seconds < 60) return '${seconds}s ago';
    final minutes = seconds ~/ 60;
    return '${minutes}m ago';
  }

  static double _distanceKm(LatLng a, LatLng b) {
    const earthRadius = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
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

  static double _rad(double value) => value * math.pi / 180;
}

class _TrackingStateBadge extends StatelessWidget {
  final String state;

  const _TrackingStateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      'live' => 'LIVE',
      'stale' => 'STALE',
      'inaccurate' => 'LOW ACCURACY',
      _ => 'GPS',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: state == 'live' ? const Color(0xFFE9F3ED) : AppColors.beige,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.green,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
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
    return SizedBox(
      width: 145,
      child: Row(
        children: [
          Icon(icon, color: AppColors.green, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 8.8),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
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
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: foreground, size: 24),
    );
  }
}

class _TrackingUnavailableCard extends StatelessWidget {
  final String message;
  final bool loading;
  final Future<void> Function()? onRefresh;

  const _TrackingUnavailableCard({
    required this.message,
    this.loading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
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
          if (onRefresh != null)
            IconButton(
              tooltip: 'Refresh GPS',
              onPressed: loading ? null : () => onRefresh!(),
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }
}
