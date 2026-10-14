import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_config.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Sign in with Apple, Google or an email link. The same Firebase account
/// works in the app and on the website.
class AuthRepository {
  AuthRepository([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _googleReady = false;

  static const _pendingEmailKey = 'pending_email_link';

  Stream<User?> get changes => _auth.authStateChanges();
  User? get user => _auth.currentUser;

  /// e.g. `Apple, email`
  String get providerSummary {
    final ids = user?.providerData.map((p) => p.providerId).toSet() ?? {};
    return [
      if (ids.contains('apple.com')) 'Apple',
      if (ids.contains('google.com')) 'Google',
      if (ids.contains('password') || ids.contains('emailLink')) 'email',
    ].join(', ');
  }

  Future<void> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    await _guard(() async {
      if (kIsWeb) {
        await _auth.signInWithPopup(provider);
      } else {
        await _auth.signInWithProvider(provider);
      }
    });
  }

  Future<void> signInWithGoogle() async {
    await _guard(() async {
      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider());
        return;
      }
      await _ensureGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Google did not return a sign-in token.');
      }
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    });
  }

  Future<void> _ensureGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleServerClientId.isEmpty
          ? null
          : AppConfig.googleServerClientId,
    );
    _googleReady = true;
  }

  ActionCodeSettings get _linkSettings => ActionCodeSettings(
    url: 'https://${AppConfig.webDomain}/finish-sign-in',
    handleCodeInApp: true,
    androidPackageName: AppConfig.androidPackage,
    androidInstallApp: true,
    iOSBundleId: AppConfig.iosBundleId,
    linkDomain: AppConfig.webDomain,
  );

  Future<void> sendEmailLink(String email) async {
    await _guard(() async {
      await _auth.sendSignInLinkToEmail(
        email: email.trim(),
        actionCodeSettings: _linkSettings,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingEmailKey, email.trim());
    });
  }

  Future<String?> pendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingEmailKey);
  }

  bool isEmailLink(String link) => _auth.isSignInWithEmailLink(link);

  /// Completes sign-in from the link in the email. [email] is needed when
  /// the link is opened on a different device from the one that asked.
  Future<void> completeEmailLink(String link, {String? email}) async {
    final address = email ?? await pendingEmail();
    if (address == null || address.isEmpty) {
      throw const AuthFailure('Enter the email address the link was sent to.');
    }
    await _guard(() async {
      await _auth.signInWithEmailLink(email: address, emailLink: link);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingEmailKey);
    });
  }

  /// Account deletion needs a fresh sign-in.
  Future<void> reauthenticate() async {
    final u = user;
    if (u == null) throw const AuthFailure('You are signed out.');
    final ids = u.providerData.map((p) => p.providerId).toSet();
    await _guard(() async {
      if (ids.contains('apple.com')) {
        final p = AppleAuthProvider();
        kIsWeb
            ? await u.reauthenticateWithPopup(p)
            : await u.reauthenticateWithProvider(p);
      } else if (ids.contains('google.com')) {
        if (kIsWeb) {
          await u.reauthenticateWithPopup(GoogleAuthProvider());
        } else {
          await _ensureGoogle();
          final account = await GoogleSignIn.instance.authenticate();
          await u.reauthenticateWithCredential(
            GoogleAuthProvider.credential(
              idToken: account.authentication.idToken,
            ),
          );
        }
      } else {
        // Email-link accounts confirm by signing in from a fresh link.
        throw const AuthFailure(
          'For your security, sign out and back in with a new email link, '
          'then delete your account within 5 minutes.',
        );
      }
    });
  }

  Future<void> signOut() async {
    if (!kIsWeb && _googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('');
      }
      throw AuthFailure('Google sign-in did not finish (${e.code.name}).');
    }
  }

  static String _message(FirebaseAuthException e) => switch (e.code) {
    'invalid-email' => 'That email address does not look right.',
    'invalid-action-code' || 'expired-action-code' =>
      'This sign-in link has expired or was already used. Ask for a new one.',
    'network-request-failed' => 'Waiting for connection. Try again shortly.',
    'user-disabled' => 'This account has been switched off.',
    'too-many-requests' => 'Too many attempts. Wait a minute and try again.',
    'popup-closed-by-user' ||
    'canceled' ||
    'web-context-canceled' ||
    'cancelled-popup-request' => '',
    'requires-recent-login' => 'Please sign in again to confirm.',
    'account-exists-with-different-credential' =>
      'You already have an account with this email. Sign in the way you did before.',
    'operation-not-allowed' =>
      'This sign-in method is not switched on yet for Home Vault.',
    _ => e.message ?? 'Sign-in did not work. Try again.',
  };
}
