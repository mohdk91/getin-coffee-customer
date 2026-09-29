import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../location/location_permission_screen.dart';
import 'phone_login_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  InputDecoration _field(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.muted),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(height: 14),
              const Text(
                'Create an Account',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your Getin Coffee account and order your way.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: _field('First name', Icons.person_outline),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: _field('Last name', Icons.person_outline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: _field('Email address', Icons.email_outlined),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PhoneLoginScreen(),
                    ),
                  );
                },
                child: IgnorePointer(
                  child: TextField(
                    decoration: _field('Phone number', Icons.phone_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: _field('Password', Icons.lock_outline_rounded),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration:
                    _field('Confirm password', Icons.lock_outline_rounded),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration:
                    _field('Referral code (optional)', Icons.card_giftcard),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LocationPermissionScreen(),
                      ),
                      (_) => false,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.beige,
                  ),
                  child: const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
