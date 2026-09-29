import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/reviews/customer_review_store.dart';
import 'package:getin_coffee/core/settings/customer_settings_store.dart';

void main() {
  test('pickup service review serializes for local persistence', () {
    final review = CustomerServiceReview(
      id: 'service-1',
      orderId: 'GC-10491',
      kind: 'employee',
      subjectName: 'Mariam Adel',
      rating: 5,
      comment: 'Friendly staff · Fast service',
      createdAt: DateTime(2026, 9, 24, 12),
    );

    final restored = CustomerServiceReview.fromJson(review.toJson());

    expect(restored.orderId, 'GC-10491');
    expect(restored.kind, 'employee');
    expect(restored.subjectName, 'Mariam Adel');
    expect(restored.rating, 5);
  });

  test('settings exposes the expanded demo language set', () {
    expect(
      CustomerSettingsStore.supportedLanguages,
      containsAll(<String>{
        'English',
        'العربية',
        'Français',
        'Español',
        'Italiano',
        'Türkçe',
        '简体中文',
      }),
    );
  });
}
