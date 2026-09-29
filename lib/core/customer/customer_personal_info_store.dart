import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared local/demo personal information state.
///
/// Task #11 persists gender locally so Profile screens do not each maintain a
/// separate fake value. Laravel can later replace this store as the source of
/// truth while keeping the same UI contract.
class CustomerPersonalInfoStore {
  CustomerPersonalInfoStore._();

  static const String _genderKey = 'getin_demo_customer_gender';

  static const List<String> genderOptions = <String>[
    'Male',
    'Female',
    'Prefer not to say',
  ];

  static final ValueNotifier<String> gender = ValueNotifier<String>(
    'Prefer not to say',
  );

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_genderKey);
    if (saved != null && genderOptions.contains(saved)) {
      gender.value = saved;
    } else if (!genderOptions.contains(gender.value)) {
      gender.value = 'Prefer not to say';
    }
  }

  static Future<void> setGender(String value) async {
    if (!genderOptions.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Unsupported gender option');
    }
    gender.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, value);
  }
}
