import 'package:flutter/material.dart';

import '../../core/auth/customer_auth_store.dart';
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
  bool _hidden = true;
  bool _authenticating = false;

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
    if (_authenticating) return;
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
              const SizedBox(height: 38),
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
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _authenticating ? null : _signIn,
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
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _authenticating
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PhoneLoginScreen(),
                            ),
                          ),
                  icon: const Icon(Icons.phone_iphone_rounded),
                  label: const Text('Sign In with Mobile Number'),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: TextButton(
                  onPressed: _authenticating
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
