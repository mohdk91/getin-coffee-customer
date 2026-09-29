import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/customer/customer_personal_info_store.dart';

void main() {
  test('Task 11.1 exposes only the approved gender options', () {
    expect(
      CustomerPersonalInfoStore.genderOptions,
      <String>['Male', 'Female', 'Prefer not to say'],
    );
    expect(
      CustomerPersonalInfoStore.genderOptions.contains('Non-binary'),
      isFalse,
    );
  });
}
