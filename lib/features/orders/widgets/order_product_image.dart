import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OrderProductImage extends StatelessWidget {
  final String source;
  final double width;
  final double height;

  const OrderProductImage({
    super.key,
    required this.source,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final value = source.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    if (value.isNotEmpty) {
      return Image.asset(
        value,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: AppColors.beige.withOpacity(0.35),
        alignment: Alignment.center,
        child: const Icon(
          Icons.local_cafe_outlined,
          color: AppColors.green,
        ),
      );
}
