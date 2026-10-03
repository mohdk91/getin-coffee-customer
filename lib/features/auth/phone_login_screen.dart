import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

import '../../core/auth/customer_auth_store.dart';
import '../../core/auth/customer_firebase_auth_service.dart';
import '../../core/config/customer_mobile_app_settings.dart';
import '../../core/theme/app_colors.dart';
import 'customer_auth_flow.dart';
import 'firebase_phone_otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _code = '+20';
  String _flag = '🇪🇬';
  bool _busy = false;
  bool _hidden = true;
  late bool _passwordMode;

  CustomerMobileAppSettings get _settings =>
      CustomerMobileAppSettingsStore.instance.settings;

  @override
  void initState() {
    super.initState();
    _passwordMode = !_settings.phoneAuthEnabled ||
        _settings.defaultMethod == 'password';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _phoneNumber() {
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) return null;
    return '$_code$digits';
  }

  Future<void> _getCode() async {
    if (_busy) return;
    final phone = _phoneNumber();
    if (phone == null) {
      _error('Enter a valid mobile number.');
      return;
    }
    if (!_settings.phoneAuthEnabled) {
      _error('Mobile verification is not enabled yet. Use password instead.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final result = await CustomerFirebaseAuthService.instance
          .startPhoneVerification(phone);
      if (!mounted) return;
      if (result.authenticatedAutomatically) {
        await continueAfterCustomerAuthentication(context);
        return;
      }
      final session = result.session;
      if (session == null) {
        throw StateError('Firebase did not return an SMS verification session.');
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FirebasePhoneOtpScreen(session: session),
        ),
      );
    } catch (error) {
      if (mounted) _error(CustomerAuthStore.instance.userMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithPassword() async {
    if (_busy) return;
    final phone = _phoneNumber();
    if (phone == null || _passwordController.text.isEmpty) {
      _error('Enter a valid mobile number and password.');
      return;
    }
    if (!_settings.passwordEnabled) {
      _error('Password sign-in is disabled.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await CustomerAuthStore.instance.login(
        identifier: phone,
        password: _passwordController.text,
      );
      if (!mounted) return;
      await continueAfterCustomerAuthentication(context);
    } catch (error) {
      if (mounted) _error(CustomerAuthStore.instance.userMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        inputDecoration: InputDecoration(
          labelText: 'Search country or dial code',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      onSelect: (country) {
        setState(() {
          _code = '+${country.phoneCode}';
          _flag = country.flagEmoji;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canUseOtp = _settings.phoneAuthEnabled;
    final canUsePassword = _settings.passwordEnabled;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _passwordMode ? 'Sign In with Mobile' : 'Get a Sign-In Code',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              _passwordMode
                  ? 'Use the password linked to your GETIN account.'
                  : 'We’ll send a 6-digit verification code to your mobile number.',
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 32),
            Container(
              constraints: const BoxConstraints(minHeight: 58),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _busy ? null : _selectCountry,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 17,
                      ),
                      child: Text('$_flag  $_code'),
                    ),
                  ),
                  const SizedBox(height: 34, child: VerticalDivider(width: 1)),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      enabled: !_busy,
                      keyboardType: TextInputType.phone,
                      textInputAction:
                          _passwordMode ? TextInputAction.next : TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_passwordMode) _getCode();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter mobile number',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_passwordMode) ...[
              const SizedBox(height: 18),
              TextField(
                controller: _passwordController,
                enabled: !_busy,
                obscureText: _hidden,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signInWithPassword(),
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _busy
                    ? null
                    : (_passwordMode ? _signInWithPassword : _getCode),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.beige,
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.beige,
                        ),
                      )
                    : Text(_passwordMode ? 'Sign In' : 'Get Code'),
              ),
            ),
            if (!_passwordMode && canUsePassword) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: _busy ? null : () => setState(() => _passwordMode = true),
                child: const Text('Use password instead'),
              ),
            ],
            if (_passwordMode && canUseOtp) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: _busy ? null : () => setState(() => _passwordMode = false),
                child: const Text('Use Get Code instead'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
