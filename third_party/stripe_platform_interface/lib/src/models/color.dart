import 'package:flutter/painting.dart';

/// Deserialization object for colors.
///
/// This object is used to translate Flutter color objects to hex strings used by the stripe sdk.
class ColorKey {
  const ColorKey();

  static String? toJson(Color? color) {
    if (color != null) {
      return '#${color.colorHexString.toUpperCase()}';
    }
    return null;
  }

  static Color? fromJson(value) {
    throw UnimplementedError();
  }
}

extension ColorX on Color {
  String get colorHexString {
    final redHex = red.toRadixString(16).padLeft(2, '0');
    final greenHex = green.toRadixString(16).padLeft(2, '0');
    final blueHex = blue.toRadixString(16).padLeft(2, '0');
    final alphaHex = alpha.toRadixString(16).padLeft(2, '0');
    return '$alphaHex$redHex$greenHex$blueHex';
  }
}
