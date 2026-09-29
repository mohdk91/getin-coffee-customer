import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/getin_logo.dart';
import '../location/location_permission_screen.dart';
import 'phone_login_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _hidden = true;
  bool _authenticating = false;

  InputDecoration _field(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.green),
      ),
    );
  }

  Future<void> _continueAfterLogin() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);

    // Local demo: represent the async auth boundary without pretending a real
    // backend request has happened. Production will surface offline/auth
    // failures here before navigation.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _authenticating = false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPermissionScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GetinLogoMark(size: 78),
              const SizedBox(height: 28),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sign in to continue your Getin Coffee experience.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 38),
              const Text('Email Address'),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: _field('Enter email address', Icons.email_outlined),
              ),
              const SizedBox(height: 18),
              const Text('Password'),
              const SizedBox(height: 8),
              TextField(
                obscureText: _hidden,
                decoration: _field(
                  'Enter password',
                  Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Reset Password'),
                        content: const Text(
                          'For this local demo, password reset is simulated. '
                          'The production app will send a secure reset link or OTP.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Demo password reset request created.',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Send Reset'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _authenticating ? null : _continueAfterLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.beige,
                  ),
                  child: _authenticating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.beige,
                          ),
                        )
                      : const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _authenticating
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PhoneLoginScreen(),
                            ),
                          );
                        },
                  icon: const Icon(Icons.phone_iphone_rounded),
                  label: const Text('Continue with Mobile Number'),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SocialAuthButton(
                      label: 'Google',
                      icon: const _GoogleMark(),
                      onPressed: _authenticating ? null : _continueAfterLogin,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SocialAuthButton(
                      label: 'Apple',
                      icon: const Icon(
                        Icons.apple,
                        size: 22,
                        color: Colors.black,
                      ),
                      onPressed: _authenticating ? null : _continueAfterLogin,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Don’t have an account?  Sign Up',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  const _SocialAuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green,
          side: const BorderSide(
            color: AppColors.muted,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Center(child: icon),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size.square(22),
      painter: _GoogleMarkPainter(),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.20;
    final arcRect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    void arc(
      Color color,
      double start,
      double sweep,
    ) {
      canvas.drawArc(
        arcRect,
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.square,
      );
    }

    // Google-inspired four-color G mark drawn locally,
    // avoiding an additional icon dependency.
    arc(const Color(0xFF4285F4), -0.55, 1.85);
    arc(const Color(0xFF34A853), 1.30, 1.15);
    arc(const Color(0xFFFBBC05), 2.45, 0.95);
    arc(const Color(0xFFEA4335), 3.40, 1.95);

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.52,
        size.height * 0.46,
        size.width * 0.42,
        stroke,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(
    covariant _GoogleMarkPainter oldDelegate,
  ) {
    return false;
  }
}
