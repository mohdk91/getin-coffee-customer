import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/customer/customer_personal_info_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gender persists in the local demo store', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    CustomerPersonalInfoStore.gender.value = 'Prefer not to say';

    await CustomerPersonalInfoStore.setGender('Male');
    expect(CustomerPersonalInfoStore.gender.value, 'Male');

    CustomerPersonalInfoStore.gender.value = 'Prefer not to say';
    await CustomerPersonalInfoStore.initialize();
    expect(CustomerPersonalInfoStore.gender.value, 'Male');
  });
}
