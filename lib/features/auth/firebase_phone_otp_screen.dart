import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/customer_auth_store.dart';
import '../../core/auth/customer_firebase_auth_service.dart';
import '../../core/config/customer_mobile_app_settings.dart';
import '../../core/theme/app_colors.dart';
import 'customer_auth_flow.dart';

class FirebasePhoneOtpScreen extends StatefulWidget {
  final FirebasePhoneVerificationSession session;

  const FirebasePhoneOtpScreen({
    super.key,
    required this.session,
  });

  @override
  State<FirebasePhoneOtpScreen> createState() =>
      _FirebasePhoneOtpScreenState();
}

class _FirebasePhoneOtpScreenState extends State<FirebasePhoneOtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  late FirebasePhoneVerificationSession _session;
  Timer? _timer;
  late int _remainingSeconds;
  bool _verifying = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _restartCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _restartCooldown() {
    _timer?.cancel();
    final configured = CustomerMobileAppSettingsStore.instance.settings
        .otpResendSeconds;
    _remainingSeconds = configured < 30 ? 30 : configured;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  String get _code => _controllers.map((controller) => controller.text).join();

  Future<void> _verify() async {
    if (_verifying) return;
    final code = _code;
    if (code.length != 6) {
      _error('Enter the complete 6-digit code.');
      return;
    }
    setState(() => _verifying = true);
    try {
      await CustomerFirebaseAuthService.instance.verifyPhoneCode(
        session: _session,
        code: code,
      );
      if (!mounted) return;
      await continueAfterCustomerAuthentication(context);
    } catch (error) {
      if (mounted) _error(CustomerAuthStore.instance.userMessage(error));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _remainingSeconds > 0) return;
    setState(() => _resending = true);
    try {
      final result = await CustomerFirebaseAuthService.instance
          .startPhoneVerification(
        _session.phoneNumber,
        forceResendingToken: _session.forceResendingToken,
      );
      if (!mounted) return;
      if (result.authenticatedAutomatically) {
        await continueAfterCustomerAuthentication(context);
        return;
      }
      final session = result.session;
      if (session == null) {
        throw StateError('Firebase did not return an SMS verification session.');
      }
      setState(() => _session = session);
      _restartCooldown();
      _error('A new verification code was sent.');
    } catch (error) {
      if (mounted) _error(CustomerAuthStore.instance.userMessage(error));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _resendLabel {
    if (_resending) return 'Sending…';
    if (_remainingSeconds > 0) {
      final seconds = _remainingSeconds.toString().padLeft(2, '0');
      return 'Resend Code in 00:$seconds';
    }
    return 'Resend Code';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: _verifying ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Verify Your Mobile',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to ${_session.phoneNumber}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 40),
            Row(
              children: List.generate(6, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 5 ? 0 : 7),
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
                        if (i == 5 && value.isNotEmpty) _verify();
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.beige,
                        ),
                      )
                    : const Text('Verify & Continue'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed:
                  _resending || _remainingSeconds > 0 ? null : _resend,
              child: Text(_resendLabel),
            ),
          ],
        ),
      ),
    );
  }
}
