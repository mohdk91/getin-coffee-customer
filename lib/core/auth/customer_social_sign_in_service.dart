import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../network/api_exception.dart';
import 'customer_auth_store.dart';

class CustomerSocialSignInService {
  const CustomerSocialSignInService();

  Future<void> signInWithGoogle() async {
    final auth = CustomerAuthStore.instance;
    final config = auth.context.config;
    if (!config.googleSignInConfigured) {
      throw const ApiException(
        'Google Sign-In is not configured yet. Add GOOGLE_SERVER_CLIENT_ID to the app build.',
      );
    }

    final google = GoogleSignIn(
      scopes: const <String>['email', 'profile'],
      serverClientId: config.googleServerClientId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS &&
              config.googleIosClientId.isNotEmpty
          ? config.googleIosClientId
          : null,
    );

    final account = await google.signIn();
    if (account == null) {
      throw const ApiException('Google Sign-In was cancelled.');
    }
    final authentication = await account.authentication;
    final idToken = authentication.idToken?.trim() ?? '';
    if (idToken.isEmpty) {
      throw const ApiException('Google did not return an identity token.');
    }

    await auth.socialLogin(
      provider: 'google',
      identityToken: idToken,
      displayName: account.displayName,
    );
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
