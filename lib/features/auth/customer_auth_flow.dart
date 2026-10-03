import 'package:flutter/material.dart';

import '../../core/auth/customer_account_sync.dart';
import '../../core/auth/customer_auth_store.dart';
import '../location/location_permission_screen.dart';
import 'otp_screen.dart';
import 'social_phone_screen.dart';

Future<void> continueAfterCustomerAuthentication(BuildContext context) async {
  final auth = CustomerAuthStore.instance;
  var customer = auth.customer;
  if (customer == null) return;
  await CustomerAccountSync.refreshAfterAuthentication();
  customer = auth.customer ?? customer;
  if (!context.mounted) return;

  if (!auth.usesApi || customer.phoneVerified) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
      (_) => false,
    );
    return;
  }

  if (customer.phone.trim().isEmpty) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SocialPhoneScreen()),
      (_) => false,
    );
    return;
  }

  var resendAfterSeconds = 30;
  try {
    final data = await auth.sendOtp();
    final serverSeconds = (data['resend_after_seconds'] as num?)?.toInt();
    if (serverSeconds != null && serverSeconds > resendAfterSeconds) {
      resendAfterSeconds = serverSeconds;
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.userMessage(error))),
      );
    }
  }
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => OtpScreen(
        phoneNumber: customer!.phone,
        initialResendSeconds: resendAfterSeconds,
      ),
    ),
    (_) => false,
  );
}
