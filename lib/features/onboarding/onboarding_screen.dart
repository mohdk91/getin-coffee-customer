import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../auth/sign_in_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final items = const [
    (
      image: 'assets/images/onboarding_1.png',
      title: 'Discover Your Coffee',
      text:
          'Explore Getin favorites, seasonal creations and coffee made for every moment.'
    ),
    (
      image: 'assets/images/onboarding_2.png',
      title: 'Order Your Way',
      text:
          'Choose your favorites in the app and collect them quickly from Getin pickup.'
    ),
    (
      image: 'assets/images/onboarding_3.png',
      title: 'Delivered to You',
      text:
          'Enjoy your Getin favorites with convenient delivery straight to your door.'
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  void _next() {
    if (_index == items.length - 1) {
      _finish();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenDark,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(items[i].image, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x08000000),
                          Color(0x440D211C),
                          Color(0xF50D211C),
                        ],
                        stops: [0.35, 0.64, 1],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 26),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: _finish,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.beige,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      items[_index].title,
                      style: const TextStyle(
                        color: AppColors.beige,
                        fontSize: 31,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      items[_index].text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: List.generate(
                      items.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 8),
                        width: i == _index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index ? AppColors.gold : Colors.white54,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.beige,
                        foregroundColor: AppColors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _index == items.length - 1 ? 'Get Started' : 'Continue',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
