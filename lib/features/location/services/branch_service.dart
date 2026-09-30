import 'dart:math';

import '../../../core/catalog/customer_catalog_store.dart';
import '../../../core/constants/app_images.dart';
import '../models/branch.dart';

class BranchDistance {
  final Branch branch;
  final double distanceKm;

  const BranchDistance({required this.branch, required this.distanceKm});
}

class BranchService {
  static const _developmentFallback = <Branch>[
    Branch(
      id: 1,
      name: 'Getin Stanley',
      latitude: 31.2452,
      longitude: 29.9667,
      deliveryEnabled: true,
      pickupEnabled: true,
    ),
    Branch(
      id: 2,
      name: 'Getin San Stefano',
      latitude: 31.2469,
      longitude: 29.9735,
      deliveryEnabled: true,
      pickupEnabled: true,
    ),
    Branch(
      id: 3,
      name: 'Getin Smouha',
      latitude: 31.2156,
      longitude: 29.9553,
      deliveryEnabled: true,
      pickupEnabled: true,
    ),
  ];

  static List<Branch> get branches {
    final live = CustomerCatalogStore.instance.branches;
    return live.isNotEmpty ? live : _developmentFallback;
  }

  static String imageFor(Branch branch) {
    if (branch.imageUrl != null && branch.imageUrl!.trim().isNotEmpty) {
      return branch.imageUrl!;
    }
    switch (branch.id) {
      case 1:
        return AppImages.branchStanley;
      case 2:
        return AppImages.branchSanStefano;
      case 3:
        return AppImages.branchSmouha;
      default:
        return AppImages.branchStanley;
    }
  }

  Branch? nearest({
    required double latitude,
    required double longitude,
    required String serviceType,
  }) {
    final list = nearbyBranches(
      latitude: latitude,
      longitude: longitude,
      serviceType: serviceType,
    );
    return list.isEmpty ? null : list.first.branch;
  }

  List<BranchDistance> nearbyBranches({
    required double latitude,
    required double longitude,
    required String serviceType,
  }) {
    final result = branches
        .where((branch) => serviceType == 'delivery'
            ? branch.deliveryEnabled
            : branch.pickupEnabled)
        .map((branch) => BranchDistance(
              branch: branch,
              distanceKm: distanceKm(
                latitude: latitude,
                longitude: longitude,
                branch: branch,
              ),
            ))
        .toList();
    result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return result;
  }

  double distanceKm({
    required double latitude,
    required double longitude,
    required Branch branch,
  }) {
    const earthRadius = 6371.0;
    final dLat = _rad(branch.latitude - latitude);
    final dLon = _rad(branch.longitude - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(latitude)) *
            cos(_rad(branch.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double value) => value * pi / 180;
}
