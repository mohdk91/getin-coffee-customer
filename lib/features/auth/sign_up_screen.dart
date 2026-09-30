import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

import '../../core/auth/customer_auth_store.dart';
import '../../core/settings/customer_settings_store.dart';
import '../../core/theme/app_colors.dart';
import 'customer_auth_flow.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _referral = TextEditingController();
  String _phoneCode = '+20';
  String _phoneFlag = '🇪🇬';
  bool _submitting = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _referral.dispose();
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

  Future<void> _choosePhoneCountry() async {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (country) {
        setState(() {
          _phoneCode = '+${country.phoneCode}';
          _phoneFlag = country.flagEmoji;
        });
      },
    );
  }

  Future<void> _createAccount() async {
    if (_submitting) return;
    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    final email = _email.text.trim();
    final localPhone = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    final password = _password.text;
    final confirmation = _confirmPassword.text;

    if (first.isEmpty || last.isEmpty) {
      _error('Enter your first and last name.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _error('Enter a valid email address.');
      return;
    }
    if (localPhone.length < 7) {
      _error('Enter a valid mobile number.');
      return;
    }
    if (password.length < 8 || !RegExp(r'[A-Za-z]').hasMatch(password) || !RegExp(r'[0-9]').hasMatch(password)) {
      _error('Password must be at least 8 characters and include letters and numbers.');
      return;
    }
    if (password != confirmation) {
      _error('Password confirmation does not match.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final language = CustomerSettingsStore.instance.language == 'العربية' ? 'ar' : 'en';
      await CustomerAuthStore.instance.register(
        name: '$first $last',
        email: email,
        phone: '$_phoneCode$localPhone',
        password: password,
        passwordConfirmation: confirmation,
        language: language,
        referralCode: _referral.text,
      );
      if (!mounted) return;
      await continueAfterCustomerAuthentication(context);
    } catch (error) {
      if (mounted) _error(CustomerAuthStore.instance.userMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                onPressed: _submitting ? null : () => Navigator.pop(context),
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
                      controller: _firstName,
                      textInputAction: TextInputAction.next,
                      decoration: _field('First name', Icons.person_outline),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lastName,
                      textInputAction: TextInputAction.next,
                      decoration: _field('Last name', Icons.person_outline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _field('Email address', Icons.email_outlined),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: _field('Phone number', Icons.phone_outlined).copyWith(
                  prefixIconConstraints: const BoxConstraints(minWidth: 94),
                  prefixIcon: InkWell(
                    onTap: _choosePhoneCountry,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_phoneFlag),
                          const SizedBox(width: 5),
                          Text(_phoneCode),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.next,
                decoration: _field(
                  'Password',
                  Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPassword,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.next,
                decoration: _field('Confirm password', Icons.lock_outline_rounded),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _referral,
                textCapitalization: TextCapitalization.characters,
                decoration: _field('Referral code (optional)', Icons.card_giftcard),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _submitting ? null : _createAccount,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.beige,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.beige),
                        )
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
