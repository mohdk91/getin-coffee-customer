import 'dart:math';

import '../../../core/catalog/customer_catalog_store.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/customer/customer_country.dart';
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
    final store = CustomerCatalogStore.instance;
    final live = store.branches;
    if (live.isNotEmpty) {
      return scopeToCountry(
        live,
        CustomerCountryStore.current.value.normalizedIsoCode,
      );
    }
    return store.usesApi ? const <Branch>[] : _developmentFallback;
  }

  static List<Branch> scopeToCountry(
    Iterable<Branch> source,
    String? countryCode,
  ) {
    final rows = source.toList(growable: false);
    final normalized = countryCode?.trim().toUpperCase();
    if (rows.isEmpty || normalized == null || normalized.isEmpty) return rows;

    final matching = rows
        .where(
          (branch) => branch.countryCode?.trim().toUpperCase() == normalized,
        )
        .toList(growable: false);

    // Older APIs did not always return country metadata. Preserve the live
    // list in that case instead of making branch selection unexpectedly empty.
    return matching.isNotEmpty ? matching : rows;
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
    String? countryCode,
  }) {
    final list = nearbyBranches(
      latitude: latitude,
      longitude: longitude,
      serviceType: serviceType,
      countryCode: countryCode,
    );
    return list.isEmpty ? null : list.first.branch;
  }

  List<BranchDistance> nearbyBranches({
    required double latitude,
    required double longitude,
    required String serviceType,
    String? countryCode,
  }) {
    final normalizedCountry = countryCode?.trim().toUpperCase();
    final result = branches
        .where((branch) {
          final supportsService = serviceType == 'delivery'
              ? branch.deliveryEnabled
              : branch.pickupEnabled;
          if (!supportsService) return false;
          if (normalizedCountry == null || normalizedCountry.isEmpty) {
            return true;
          }
          return branch.countryCode?.trim().toUpperCase() == normalizedCountry;
        })
        .map(
          (branch) => BranchDistance(
            branch: branch,
            distanceKm: distanceKm(
              latitude: latitude,
              longitude: longitude,
              branch: branch,
            ),
          ),
        )
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
