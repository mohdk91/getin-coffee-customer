import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/customer/customer_profile_photo_store.dart';
import '../../core/theme/app_colors.dart';

enum _ProfilePhotoAction {
  gallery,
  camera,
  remove,
}

Future<void> showProfilePhotoActions(BuildContext context) async {
  final hasPhoto = CustomerProfilePhotoStore.photoPath.value != null;

  final action = await showModalBottomSheet<_ProfilePhotoAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Profile photo',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasPhoto
                    ? 'Replace your photo or remove the current one.'
                    : 'Choose a photo from your gallery or take a new one.',
                style: const TextStyle(
                  color: Color(0x8F000000),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              _PhotoActionTile(
                icon: Icons.photo_library_outlined,
                title:
                    hasPhoto ? 'Replace from Gallery' : 'Choose from Gallery',
                onTap: () => Navigator.pop(
                  sheetContext,
                  _ProfilePhotoAction.gallery,
                ),
              ),
              _PhotoActionTile(
                icon: Icons.photo_camera_outlined,
                title: hasPhoto ? 'Replace with Camera' : 'Take Photo',
                onTap: () => Navigator.pop(
                  sheetContext,
                  _ProfilePhotoAction.camera,
                ),
              ),
              if (hasPhoto)
                _PhotoActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Remove Photo',
                  danger: true,
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _ProfilePhotoAction.remove,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  if (action == null || !context.mounted) return;

  if (action == _ProfilePhotoAction.remove) {
    await CustomerProfilePhotoStore.remove();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo removed.')),
    );
    return;
  }

  final source = action == _ProfilePhotoAction.camera
      ? ImageSource.camera
      : ImageSource.gallery;

  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
      maxHeight: 1600,
      requestFullMetadata: false,
    );

    if (picked == null) return;

    await CustomerProfilePhotoStore.importFromPath(picked.path);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo updated.')),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          source == ImageSource.camera
              ? 'Camera is unavailable or permission was not granted.'
              : 'Gallery is unavailable or permission was not granted.',
        ),
      ),
    );
  }
}

class _PhotoActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  const _PhotoActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red.shade700 : AppColors.green;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: danger ? Colors.red.shade50 : AppColors.cream,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: color),
      onTap: onTap,
    );
  }
}
