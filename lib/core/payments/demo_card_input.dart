class DemoCardInput {
  const DemoCardInput._();

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String detectBrand(String value) {
    final digits = digitsOnly(value);
    if (digits.isEmpty) {
      return 'CARD';
    }

    if (digits.startsWith('4')) {
      return 'VISA';
    }

    if (digits.length >= 2) {
      final firstTwo = int.tryParse(digits.substring(0, 2));
      if (firstTwo != null && firstTwo >= 51 && firstTwo <= 55) {
        return 'MASTERCARD';
      }
    }

    if (digits.length >= 4) {
      final firstFour = int.tryParse(digits.substring(0, 4));
      if (firstFour != null && firstFour >= 2221 && firstFour <= 2720) {
        return 'MASTERCARD';
      }
    }

    return 'CARD';
  }

  static bool hasValidLength(String value, String brand) {
    final length = digitsOnly(value).length;
    switch (brand) {
      case 'VISA':
        return length == 13 || length == 16 || length == 19;
      case 'MASTERCARD':
        return length == 16;
      default:
        return false;
    }
  }

  static bool passesLuhn(String value) {
    final digits = digitsOnly(value);
    if (digits.length < 12) {
      return false;
    }

    var sum = 0;
    var doubleDigit = false;
    for (var index = digits.length - 1; index >= 0; index--) {
      var digit = int.parse(digits[index]);
      if (doubleDigit) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      doubleDigit = !doubleDigit;
    }
    return sum % 10 == 0;
  }

  static String last4(String value) {
    final digits = digitsOnly(value);
    if (digits.length < 4) {
      return digits;
    }
    return digits.substring(digits.length - 4);
  }
}
