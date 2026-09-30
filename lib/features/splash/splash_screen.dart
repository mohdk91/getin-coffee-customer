import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../core/auth/customer_auth_store.dart';
import '../../core/content/mobile_app_content_models.dart';
import '../../core/content/mobile_app_content_store.dart';
import '../../core/theme/app_colors.dart';
import '../auth/sign_in_screen.dart';
import '../location/location_permission_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  Timer? _safetyTimer;
  bool _ready = false;
  bool _done = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final configured = MobileAppContentStore.instance.splash;
    final media = configured?.media ?? configured?.fallbackMedia;

    if (media != null && media.url.isNotEmpty && media.type == 'image') {
      if (mounted) setState(() => _imageUrl = media.url);
      _safetyTimer = Timer(const Duration(seconds: 3), _continue);
      return;
    }

    await _startVideo(media);
  }

  Future<void> _startVideo(MobileContentMedia? media) async {
    final controller = media != null && media.url.isNotEmpty
        ? VideoPlayerController.networkUrl(Uri.parse(media.url))
        : VideoPlayerController.asset('assets/videos/getin_splash_compat.mp4');
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || _done) return;
      await controller.setLooping(false);
      await controller.setVolume(0);
      controller.addListener(_videoListener);
      setState(() => _ready = true);
      _safetyTimer = Timer(
        controller.value.duration + const Duration(seconds: 2),
        _continue,
      );
      await controller.play();
    } catch (error, stackTrace) {
      debugPrint('Getin splash media error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (media != null) {
        await controller.dispose();
        _controller = null;
        await _startVideo(null);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 450));
      await _continue();
    }
  }

  void _videoListener() {
    final controller = _controller;
    if (controller == null || _done) return;
    final value = controller.value;
    if (value.hasError) {
      _continue();
      return;
    }
    if (value.isInitialized && value.duration.inMilliseconds > 0 &&
        value.position.inMilliseconds >= value.duration.inMilliseconds - 120) {
      _continue();
    }
  }

  Future<void> _continue() async {
    if (_done) return;
    _done = true;
    _safetyTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final completed =
        kReleaseMode ? (prefs.getBool('onboarding_completed') ?? false) : false;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) {
          if (!completed) return const OnboardingScreen();
          return CustomerAuthStore.instance.isAuthenticated
              ? const LocationPermissionScreen()
              : const SignInScreen();
        },
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_videoListener);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: AppColors.green,
      body: SizedBox.expand(
        child: _imageUrl != null
            ? Image.network(
                _imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: AppColors.green),
              )
            : _ready && controller != null && controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  )
                : const ColoredBox(color: AppColors.green),
      ),
    );
  }
}
