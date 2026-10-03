import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

import '../../core/auth/customer_auth_store.dart';
import '../../core/theme/app_colors.dart';
import 'otp_screen.dart';

class SocialPhoneScreen extends StatefulWidget {
  const SocialPhoneScreen({super.key});

  @override
  State<SocialPhoneScreen> createState() => _SocialPhoneScreenState();
}

class _SocialPhoneScreenState extends State<SocialPhoneScreen> {
  final _phoneController = TextEditingController();
  String _code = '+20';
  String _countryCode = 'EG';
  String _flag = '🇪🇬';
  bool _saving = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _selectCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (country) {
        setState(() {
          _code = '+${country.phoneCode}';
          _countryCode = country.countryCode;
          _flag = country.flagEmoji;
        });
      },
    );
  }

  Future<void> _continue() async {
    if (_saving) return;
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) {
      _error('Enter a valid mobile number.');
      return;
    }
    final phone = '$_code$digits';
    setState(() => _saving = true);
    try {
      final auth = CustomerAuthStore.instance;
      await auth.updateProfile(<String, dynamic>{
        'phone': phone,
        'country_code': _countryCode,
      });
      final data = await auth.sendOtp();
      if (!mounted) return;
      final seconds = (data['resend_after_seconds'] as num?)?.toInt() ?? 30;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: phone,
            initialResendSeconds: seconds < 30 ? 30 : seconds,
          ),
        ),
      );
    } catch (error) {
      if (mounted) _error(CustomerAuthStore.instance.userMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          children: [
            const Text(
              'Add Your Mobile Number',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We use your mobile number for order updates and account verification.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 34),
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
                    onTap: _saving ? null : _selectCountry,
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
                      enabled: !_saving,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _continue(),
                      decoration: const InputDecoration(
                        hintText: 'Enter phone number',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _saving ? null : _continue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.beige,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.beige,
                        ),
                      )
                    : const Text('Send Verification Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
