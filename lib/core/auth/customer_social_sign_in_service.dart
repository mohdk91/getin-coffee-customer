import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../network/api_exception.dart';
import 'customer_auth_store.dart';
import 'customer_firebase_auth_service.dart';

class CustomerSocialSignInService {
  const CustomerSocialSignInService();

  Future<void> signInWithGoogle() async {
    await CustomerFirebaseAuthService.instance.signInWithGoogle();
  }

  Future<void> signInWithApple() async {
    final auth = CustomerAuthStore.instance;
    final config = auth.context.config;
    final rawNonce = _randomNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    WebAuthenticationOptions? webOptions;
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (!config.appleAndroidSignInConfigured) {
        throw const ApiException(
          'Apple Sign-In on Android needs APPLE_SERVICE_ID and an HTTPS APPLE_REDIRECT_URI. It is already available for the iOS build.',
        );
      }
      webOptions = WebAuthenticationOptions(
        clientId: config.appleServiceId,
        redirectUri: Uri.parse(config.appleRedirectUri),
      );
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const <AppleIDAuthorizationScopes>[
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
      webAuthenticationOptions: webOptions,
    );

    final identityToken = credential.identityToken?.trim() ?? '';
    if (identityToken.isEmpty) {
      throw const ApiException('Apple did not return an identity token.');
    }
    final parts = <String>[
      credential.givenName?.trim() ?? '',
      credential.familyName?.trim() ?? '',
    ].where((part) => part.isNotEmpty).toList();

    await auth.socialLogin(
      provider: 'apple',
      identityToken: identityToken,
      nonce: rawNonce,
      displayName: parts.isEmpty ? null : parts.join(' '),
    );
  }

  String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List<String>.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
