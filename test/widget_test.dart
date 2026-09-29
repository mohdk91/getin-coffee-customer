import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/app.dart';

void main() {
  test('GetinCoffeeApp can be created', () {
    const app = GetinCoffeeApp();

    expect(
      app,
      isA<GetinCoffeeApp>(),
    );
  });
}
