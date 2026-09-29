import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../auth/sign_in_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    final controller = VideoPlayerController.asset(
      'assets/videos/getin_splash_compat.mp4',
    );
    _controller = controller;

    try {
      await controller.initialize();

      if (!mounted || _done) return;

      await controller.setLooping(false);
      await controller.setVolume(0);
      controller.addListener(_videoListener);

      setState(() {
        _ready = true;
      });

      final duration = controller.value.duration;
      _safetyTimer = Timer(
        duration + const Duration(seconds: 2),
        _continue,
      );

      await controller.play();
    } catch (error, stackTrace) {
      debugPrint('Getin splash video error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        await Future<void>.delayed(
          const Duration(milliseconds: 450),
        );
        await _continue();
      }
    }
  }

  void _videoListener() {
    final controller = _controller;
    if (controller == null || _done) return;

    final value = controller.value;

    if (value.hasError) {
      debugPrint(
        'Getin splash playback error: ${value.errorDescription}',
      );
      _continue();
      return;
    }

    if (!value.isInitialized) return;

    final duration = value.duration.inMilliseconds;
    final position = value.position.inMilliseconds;

    if (duration > 0 && position >= duration - 120) {
      _continue();
    }
  }

  Future<void> _continue() async {
    if (_done) return;

    _done = true;
    _safetyTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();

    // During development, always replay onboarding on every app launch.
    // In production/release builds, honor the saved completion flag.
    final completed =
        kReleaseMode ? (prefs.getBool('onboarding_completed') ?? false) : false;

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) {
          return completed ? const SignInScreen() : const OnboardingScreen();
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
    );

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
        child: _ready && controller != null && controller.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            : const ColoredBox(
                color: AppColors.green,
              ),
      ),
    );
  }
}
