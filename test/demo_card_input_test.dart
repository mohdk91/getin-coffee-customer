import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/payments/demo_card_input.dart';

void main() {
  group('DemoCardInput', () {
    test('detects Visa from number prefix', () {
      expect(DemoCardInput.detectBrand('4242 4242'), 'VISA');
    });

    test('detects Mastercard legacy range', () {
      expect(DemoCardInput.detectBrand('5555 5555'), 'MASTERCARD');
    });

    test('detects Mastercard 2-series range', () {
      expect(DemoCardInput.detectBrand('2221 0000'), 'MASTERCARD');
      expect(DemoCardInput.detectBrand('2720 0000'), 'MASTERCARD');
    });

    test('validates common demo Luhn numbers', () {
      expect(DemoCardInput.passesLuhn('4242 4242 4242 4242'), isTrue);
      expect(DemoCardInput.passesLuhn('5555 5555 5555 4444'), isTrue);
      expect(DemoCardInput.passesLuhn('4242 4242 4242 4243'), isFalse);
    });

    test('extracts last four digits', () {
      expect(DemoCardInput.last4('4242 4242 4242 4242'), '4242');
    });
  });
}
