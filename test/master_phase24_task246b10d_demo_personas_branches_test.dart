import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/membership/customer_membership_store.dart';
import 'package:getin_coffee/features/location/models/branch.dart';
import 'package:getin_coffee/features/location/services/branch_service.dart';

void main() {
  test('Task 246B-10D keeps paid membership separate for two demo personas',
      () {
    expect(
      CustomerMembershipStore.isDemoMemberEmail('MEMBER.DEMO@getin.coffee'),
      isTrue,
    );
    expect(
      CustomerMembershipStore.isDemoStandardEmail('standard.demo@getin.coffee'),
      isTrue,
    );
    expect(
      CustomerMembershipStore.isDemoMemberEmail('standard.demo@getin.coffee'),
      isFalse,
    );
  });

  test('Task 246B-10D scopes six live demo branches to the selected country',
      () {
    const branches = <Branch>[
      Branch(
        id: 1,
        name: 'GETIN Stanley',
        latitude: 31.2399,
        longitude: 29.9648,
        deliveryEnabled: true,
        pickupEnabled: true,
        countryCode: 'EG',
      ),
      Branch(
        id: 2,
        name: 'GETIN San Stefano',
        latitude: 31.2469,
        longitude: 29.9735,
        deliveryEnabled: true,
        pickupEnabled: true,
        countryCode: 'EG',
      ),
      Branch(
        id: 3,
        name: 'GETIN Smouha',
        latitude: 31.2156,
        longitude: 29.9553,
        deliveryEnabled: true,
        pickupEnabled: true,
        countryCode: 'EG',
      ),
      Branch(
        id: 4,
        name: 'GETIN Nişantaşı',
        latitude: 41.0480,
        longitude: 28.9920,
        deliveryEnabled: true,
        pickupEnabled: true,
        countryCode: 'TR',
      ),
      Branch(
        id: 5,
        name: 'GETIN Kadıköy',
        latitude: 40.9909,
        longitude: 29.0280,
        deliveryEnabled: true,
        pickupEnabled: true,
        countryCode: 'TR',
      ),
      Branch(
        id: 6,
        name: 'GETIN Beşiktaş',
        latitude: 41.0430,
        longitude: 29.0094,
        deliveryEnabled: true,
        pickupEnabled: true,
        countryCode: 'TR',
      ),
    ];

    final egypt = BranchService.scopeToCountry(branches, 'EG');
    final turkey = BranchService.scopeToCountry(branches, 'tr');

    expect(egypt.map((branch) => branch.name), <String>[
      'GETIN Stanley',
      'GETIN San Stefano',
      'GETIN Smouha',
    ]);
    expect(turkey.map((branch) => branch.name), <String>[
      'GETIN Nişantaşı',
      'GETIN Kadıköy',
      'GETIN Beşiktaş',
    ]);
  });

  test('Task 246B-10D preserves live branches when country metadata is absent',
      () {
    const legacy = <Branch>[
      Branch(
        id: 1,
        name: 'Legacy branch',
        latitude: 0,
        longitude: 0,
        deliveryEnabled: true,
        pickupEnabled: true,
      ),
    ];

    expect(BranchService.scopeToCountry(legacy, 'EG'), legacy);
  });
}
