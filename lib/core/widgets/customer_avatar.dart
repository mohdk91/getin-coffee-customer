import 'dart:io';

import 'package:flutter/material.dart';

import '../customer/customer_profile_photo_store.dart';
import '../theme/app_colors.dart';

class CustomerAvatar extends StatelessWidget {
  final double size;
  final String fallbackInitial;
  final bool showCameraBadge;
  final VoidCallback? onTap;

  const CustomerAvatar({
    super.key,
    required this.size,
    this.fallbackInitial = 'M',
    this.showCameraBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = ValueListenableBuilder<String?>(
      valueListenable: CustomerProfilePhotoStore.photoPath,
      builder: (context, path, child) {
        final file = path == null ? null : File(path);
        final hasPhoto = file?.existsSync() ?? false;

        return Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: AppColors.beige,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: hasPhoto
              ? Image.file(
                  file!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _FallbackInitial(initial: fallbackInitial, size: size),
                )
              : _FallbackInitial(initial: fallbackInitial, size: size),
        );
      },
    );

    final content = showCameraBadge
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              Positioned(
                right: -2,
                bottom: 0,
                child: Container(
                  width: size * 0.36,
                  height: size * 0.36,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.beige,
                    size: size * 0.19,
                  ),
                ),
              ),
            ],
          )
        : avatar;

    if (onTap == null) return content;

    return Semantics(
      button: true,
      label: 'Edit profile photo',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _FallbackInitial extends StatelessWidget {
  final String initial;
  final double size;

  const _FallbackInitial({
    required this.initial,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      initial,
      style: TextStyle(
        color: AppColors.green,
        fontSize: size * 0.38,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
