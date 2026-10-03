import 'package:flutter/material.dart';

import '../../core/auth/customer_auth_store.dart';
import '../../core/auth/customer_social_sign_in_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/getin_logo.dart';
import 'customer_auth_flow.dart';
import 'phone_login_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _social = const CustomerSocialSignInService();
  bool _hidden = true;
  bool _authenticating = false;
  String? _socialProvider;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _field(String hint, IconData icon, {Widget? suffix}) {
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

  Future<void> _signIn() async {
    if (_authenticating || _socialProvider != null) return;
    final identifier = _identifier.text.trim();
    final password = _password.text;
    if (identifier.isEmpty || password.isEmpty) {
      _showError('Enter your email/mobile number and password.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _authenticating = true);
    try {
      await CustomerAuthStore.instance.login(
        identifier: identifier,
        password: password,
      );
      if (!mounted) return;
      await continueAfterCustomerAuthentication(context);
    } catch (error) {
      if (mounted) _showError(CustomerAuthStore.instance.userMessage(error));
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  Future<void> _socialSignIn(String provider) async {
    if (_authenticating || _socialProvider != null) return;
    setState(() => _socialProvider = provider);
    try {
      if (provider == 'google') {
        await _social.signInWithGoogle();
      } else {
        await _social.signInWithApple();
      }
      if (!mounted) return;
      await continueAfterCustomerAuthentication(context);
    } catch (error) {
      if (mounted) _showError(CustomerAuthStore.instance.userMessage(error));
    } finally {
      if (mounted) setState(() => _socialProvider = null);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _socialButton({
    required String provider,
    required Widget icon,
    required String label,
  }) {
    final loading = _socialProvider == provider;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _authenticating || _socialProvider != null
            ? null
            : () => _socialSignIn(provider),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : icon,
        label: Text(label),
      ),
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
                style: TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 34),
              const Text('Email or Mobile Number'),
              const SizedBox(height: 8),
              TextField(
                controller: _identifier,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _field(
                  'Enter email or mobile number',
                  Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 18),
              const Text('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _password,
                obscureText: _hidden,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
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
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _authenticating || _socialProvider != null
                      ? null
                      : _signIn,
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
              const SizedBox(height: 22),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 18),
              _socialButton(
                provider: 'google',
                icon: const _GoogleMark(),
                label: 'Continue with Google',
              ),
              const SizedBox(height: 12),
              _socialButton(
                provider: 'apple',
                icon: const Icon(Icons.apple, size: 23),
                label: 'Continue with Apple',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _authenticating || _socialProvider != null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PhoneLoginScreen(),
                            ),
                          ),
                  icon: const Icon(Icons.phone_iphone_rounded),
                  label: const Text('Continue with Mobile Number'),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: _authenticating || _socialProvider != null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                  child: const Text('Don’t have an account?  Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }
}
