import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/features/location/models/branch.dart';
import 'package:getin_coffee/features/location/services/branch_service.dart';

void main() {
  test('Phase 4 nearby branch distance remains deterministic', () {
    const branch = Branch(
      id: 9001,
      name: 'Test',
      latitude: 31.2452,
      longitude: 29.9667,
      deliveryEnabled: true,
      pickupEnabled: true,
    );
    final distance = BranchService().distanceKm(
      latitude: 31.2000,
      longitude: 29.9000,
      branch: branch,
    );
    expect(distance, greaterThan(0));
  });
}
