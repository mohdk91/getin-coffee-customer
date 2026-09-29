import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local/demo customer profile photo state.
///
/// The app stores only a local file path. A future Laravel integration can
/// replace [importFromPath] with an authenticated upload and keep the same
/// ValueNotifier-driven UI.
class CustomerProfilePhotoStore {
  static const String _preferenceKey = 'customer_profile_photo_path_v1';
  static const String _directoryName = 'customer_profile';

  static final ValueNotifier<String?> photoPath = ValueNotifier<String?>(null);

  static SharedPreferences? _preferences;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    _preferences = await SharedPreferences.getInstance();
    final savedPath = _preferences?.getString(_preferenceKey);

    if (savedPath != null && savedPath.isNotEmpty) {
      final savedFile = File(savedPath);
      if (await savedFile.exists()) {
        photoPath.value = savedPath;
      } else {
        await _preferences?.remove(_preferenceKey);
      }
    }

    _initialized = true;
  }

  static Future<void> importFromPath(String sourcePath) async {
    await initialize();

    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('The selected profile photo could not be found.');
    }

    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/$_directoryName');
    await directory.create(recursive: true);

    final extension = _safeExtension(sourcePath);
    final destinationPath =
        '${directory.path}/profile_${DateTime.now().millisecondsSinceEpoch}$extension';
    final copied = await source.copy(destinationPath);

    final previousPath = photoPath.value;
    photoPath.value = copied.path;
    await _preferences?.setString(_preferenceKey, copied.path);

    if (previousPath != null && previousPath != copied.path) {
      await _deleteIfPresent(previousPath);
    }
  }

  static Future<void> remove() async {
    await initialize();

    final previousPath = photoPath.value;
    photoPath.value = null;
    await _preferences?.remove(_preferenceKey);

    if (previousPath != null) {
      await _deleteIfPresent(previousPath);
    }
  }

  static String _safeExtension(String path) {
    final lastSlash = path.lastIndexOf('/') > path.lastIndexOf('\\')
        ? path.lastIndexOf('/')
        : path.lastIndexOf('\\');
    final lastDot = path.lastIndexOf('.');
    if (lastDot <= lastSlash || lastDot == path.length - 1) {
      return '.jpg';
    }

    final extension = path.substring(lastDot).toLowerCase();
    const allowed = {'.jpg', '.jpeg', '.png', '.heic', '.heif', '.webp'};
    return allowed.contains(extension) ? extension : '.jpg';
  }

  static Future<void> _deleteIfPresent(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // A stale local demo image should never break the customer experience.
    }
  }
}
