import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/customer_auth_store.dart';
import '../../core/theme/app_colors.dart';
import '../location/location_permission_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final bool returnAfterVerification;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.returnAfterVerification = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  bool _verifying = false;
  bool _resending = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    if (_verifying) return;
    final code = _controllers.map((controller) => controller.text).join();
    if (code.length != 6) {
      _error('Enter the complete 6-digit code.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    try {
      await CustomerAuthStore.instance.verifyOtp(code);
      if (!mounted) return;
      if (widget.returnAfterVerification) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
          (_) => false,
        );
      }
    } catch (error) {
      if (mounted) _error(CustomerAuthStore.instance.userMessage(error));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      final data = await CustomerAuthStore.instance.sendOtp(resend: true);
      if (!mounted) return;
      final wait = (data['resend_after_seconds'] as num?)?.toInt();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wait == null || wait <= 0
                ? 'A new verification code was sent.'
                : 'A new code was sent. You can request another in $wait seconds.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) _error(CustomerAuthStore.instance.userMessage(error));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    final gap = compact ? 4.0 : 8.0;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(compact ? 18 : 24, 18, compact ? 18 : 24, 28),
          children: [
            if (widget.returnAfterVerification)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _verifying ? null : () => Navigator.pop(context, false),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
              ),
            SizedBox(height: compact ? 18 : 28),
            Text(
              'Verify Your Number',
              style: TextStyle(
                color: AppColors.green,
                fontSize: compact ? 27 : 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to ${widget.phoneNumber}',
              style: const TextStyle(color: AppColors.muted),
            ),
            SizedBox(height: compact ? 30 : 44),
            Row(
              children: List.generate(6, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 5 ? 0 : gap),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _nodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && i < 5) {
                          _nodes[i + 1].requestFocus();
                        } else if (value.isEmpty && i > 0) {
                          _nodes[i - 1].requestFocus();
                        }
                      },
                      onSubmitted: (_) {
                        if (i == 5) _verify();
                      },
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _verifying ? null : _verify,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.beige,
                ),
                child: _verifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.beige),
                      )
                    : const Text('Verify & Continue'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _resending ? null : _resend,
              child: Text(_resending ? 'Sending…' : 'Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}
