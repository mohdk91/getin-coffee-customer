import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  String _code = '+20';
  String _flag = '🇪🇬';
  bool _sendingOtp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_sendingOtp) return;

    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid mobile number before continuing.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _sendingOtp = true);

    // Local demo: simulate an async OTP request. Production will call the
    // authentication API here and can surface offline/server failures.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _sendingOtp = false);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          phoneNumber: '$_flag $_code ${_phoneController.text.trim()}',
        ),
      ),
    );
  }

  Future<void> _selectCountry() async {
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
            borderSide: BorderSide.none,
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
    final compact = MediaQuery.sizeOf(context).width < 380;
    final systemBottom = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 24,
            18,
            compact ? 18 : 24,
            systemBottom + 24,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
            SizedBox(height: compact ? 18 : 30),
            Text(
              'Continue with Mobile',
              style: TextStyle(
                color: AppColors.green,
                fontSize: compact ? 27 : 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We’ll send a verification code to your mobile number.',
              style: TextStyle(color: AppColors.muted),
            ),
            SizedBox(height: compact ? 26 : 36),
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
                    onTap: _selectCountry,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 14,
                        vertical: 17,
                      ),
                      child: Text(
                        '$_flag  $_code',
                        style: TextStyle(fontSize: compact ? 12 : 14),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 34,
                    child: VerticalDivider(width: 1),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _sendOtp(),
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
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _sendingOtp ? null : _sendOtp,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.beige,
                ),
                child: _sendingOtp
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.beige,
                        ),
                      )
                    : const Text('Send OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
