import 'package:flutter/material.dart';

import '../../core/auth/customer_account_sync.dart';
import '../../core/auth/customer_auth_store.dart';
import '../location/location_permission_screen.dart';
import 'otp_screen.dart';

Future<void> continueAfterCustomerAuthentication(BuildContext context) async {
  final auth = CustomerAuthStore.instance;
  final customer = auth.customer;
  if (customer == null) return;
  await CustomerAccountSync.refreshAfterAuthentication();
  if (!context.mounted) return;

  if (!auth.usesApi || customer.phoneVerified) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
      (_) => false,
    );
    return;
  }

  try {
    await auth.sendOtp();
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
      builder: (_) => OtpScreen(phoneNumber: customer.phone),
    ),
    (_) => false,
  );
}
