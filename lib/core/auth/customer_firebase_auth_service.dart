import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../firebase_options.dart';
import '../network/api_exception.dart';
import 'customer_auth_store.dart';

class FirebasePhoneVerificationSession {
  final String phoneNumber;
  final String verificationId;
  final int? forceResendingToken;

  const FirebasePhoneVerificationSession({
    required this.phoneNumber,
    required this.verificationId,
    this.forceResendingToken,
  });
}

class FirebasePhoneStartResult {
  final FirebasePhoneVerificationSession? session;
  final bool authenticatedAutomatically;

  const FirebasePhoneStartResult.session(this.session)
      : authenticatedAutomatically = false;

  const FirebasePhoneStartResult.authenticated()
      : session = null,
        authenticatedAutomatically = true;
}

class CustomerFirebaseAuthService {
  CustomerFirebaseAuthService._();

  static final CustomerFirebaseAuthService instance =
      CustomerFirebaseAuthService._();

  Future<void>? _initialization;
  GoogleSignIn? _google;

  static Future<void> initialize() => instance._ensureInitialized();

  Future<void> _ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    await _ensureInitialized();

    final google = _google ??= GoogleSignIn(
      scopes: const <String>['email', 'profile'],
    );
    final account = await google.signIn();
    if (account == null) {
      throw const ApiException('Google Sign-In was cancelled.');
    }

    try {
      final tokens = await account.authentication;
      if ((tokens.idToken ?? '').trim().isEmpty &&
          (tokens.accessToken ?? '').trim().isEmpty) {
        throw const ApiException('Google did not return a usable credential.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      await _exchangeFirebaseUser(
        result.user,
        displayName: account.displayName,
      );
    } on FirebaseAuthException catch (error) {
      throw ApiException(_firebaseMessage(error), cause: error);
    }
  }

  Future<FirebasePhoneStartResult> startPhoneVerification(
    String phoneNumber, {
    int? forceResendingToken,
  }) async {
    await _ensureInitialized();
    final normalized = phoneNumber.trim();
    if (!RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(normalized)) {
      throw const ApiException('Enter a valid international mobile number.');
    }

    final completer = Completer<FirebasePhoneStartResult>();
    var settled = false;

    void complete(FirebasePhoneStartResult value) {
      if (settled || completer.isCompleted) return;
      settled = true;
      completer.complete(value);
    }

    void completeError(Object error, [StackTrace? stackTrace]) {
      if (settled || completer.isCompleted) return;
      settled = true;
      completer.completeError(error, stackTrace);
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: normalized,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
        verificationCompleted: (credential) async {
          if (settled) return;
          try {
            final result =
                await FirebaseAuth.instance.signInWithCredential(credential);
            await _exchangeFirebaseUser(result.user);
            complete(const FirebasePhoneStartResult.authenticated());
          } on FirebaseAuthException catch (error, stackTrace) {
            completeError(
              ApiException(_firebaseMessage(error), cause: error),
              stackTrace,
            );
          } catch (error, stackTrace) {
            completeError(error, stackTrace);
          }
        },
        verificationFailed: (error) {
          completeError(ApiException(_firebaseMessage(error), cause: error));
        },
        codeSent: (verificationId, resendToken) {
          complete(
            FirebasePhoneStartResult.session(
              FirebasePhoneVerificationSession(
                phoneNumber: normalized,
                verificationId: verificationId,
                forceResendingToken: resendToken,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          complete(
            FirebasePhoneStartResult.session(
              FirebasePhoneVerificationSession(
                phoneNumber: normalized,
                verificationId: verificationId,
                forceResendingToken: forceResendingToken,
              ),
            ),
          );
        },
      );
    } on FirebaseAuthException catch (error) {
      throw ApiException(_firebaseMessage(error), cause: error);
    }

    return completer.future.timeout(
      const Duration(seconds: 70),
      onTimeout: () => throw const ApiException(
        'SMS verification timed out. Please request a new code.',
      ),
    );
  }

  Future<void> verifyPhoneCode({
    required FirebasePhoneVerificationSession session,
    required String code,
  }) async {
    await _ensureInitialized();
    final smsCode = code.trim();
    if (!RegExp(r'^[0-9]{6}$').hasMatch(smsCode)) {
      throw const ApiException('Enter the complete 6-digit code.');
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: session.verificationId,
        smsCode: smsCode,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      await _exchangeFirebaseUser(result.user);
    } on FirebaseAuthException catch (error) {
      throw ApiException(_firebaseMessage(error), cause: error);
    }
  }

  Future<void> _exchangeFirebaseUser(
    User? user, {
    String? displayName,
  }) async {
    if (user == null) {
      throw const ApiException('Firebase did not return an authenticated user.');
    }
    final idToken = (await user.getIdToken(true))?.trim() ?? '';
    if (idToken.isEmpty) {
      throw const ApiException('Firebase did not return an identity token.');
    }
    await CustomerAuthStore.instance.firebaseLogin(
      idToken: idToken,
      displayName: displayName ?? user.displayName,
    );
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Laravel/Sanctum remains the authoritative app session. Firebase local
      // sign-out is best effort and must not prevent GETIN logout.
    }
    try {
      await _google?.signOut();
    } catch (_) {}
  }

  String _firebaseMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-phone-number' => 'Enter a valid mobile number.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'quota-exceeded' => 'SMS verification is temporarily unavailable.',
      'invalid-verification-code' => 'The verification code is incorrect.',
      'session-expired' => 'The verification code expired. Request a new code.',
      'network-request-failed' => 'The network is unavailable. Please try again.',
      'account-exists-with-different-credential' =>
        'This email is already linked to another sign-in method.',
      _ => error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : 'Firebase authentication failed. Please try again.',
    };
  }
}
