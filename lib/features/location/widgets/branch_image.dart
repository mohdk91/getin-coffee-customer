import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/branch.dart';
import '../services/branch_service.dart';

class BranchImage extends StatelessWidget {
  final Branch branch;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const BranchImage({
    super.key,
    required this.branch,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final path = BranchService.imageFor(branch).trim();
    Widget fallback() => Container(
          width: width,
          height: height,
          color: AppColors.beige.withOpacity(0.45),
          alignment: Alignment.center,
          child: const Icon(
            Icons.storefront_rounded,
            color: AppColors.green,
            size: 28,
          ),
        );

    Widget image;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      image = Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback(),
      );
    } else if (path.isNotEmpty) {
      image = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback(),
      );
    } else {
      image = fallback();
    }

    final radius = borderRadius;
    return radius == null
        ? image
        : ClipRRect(borderRadius: radius, child: image);
  }
}
