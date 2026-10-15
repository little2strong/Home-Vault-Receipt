import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/app_config.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Sign in with Apple, Google or an email and password.
class AuthRepository {
  AuthRepository([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _googleReady = false;

  Stream<User?> get changes => _auth.authStateChanges();
  User? get user => _auth.currentUser;

  /// e.g. `Apple, email`
  String get providerSummary {
    final ids = user?.providerData.map((p) => p.providerId).toSet() ?? {};
    return [
      if (ids.contains('apple.com')) 'Apple',
      if (ids.contains('google.com')) 'Google',
      if (ids.contains('password')) 'email',
    ].join(', ');
  }

  /// Whether confirming it's you needs the account's password.
  bool get usesPassword {
    final ids = user?.providerData.map((p) => p.providerId).toSet() ?? {};
    return ids.contains('password') &&
        !ids.contains('apple.com') &&
        !ids.contains('google.com');
  }

  Future<void> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    await _guard(() async {
      await _auth.signInWithProvider(provider);
    });
  }

  Future<void> signInWithGoogle() async {
    await _guard(() async {
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
      clientId: AppConfig.isAndroid ? null : AppConfig.googleIosClientId,
      serverClientId: AppConfig.googleServerClientId,
    );
    _googleReady = true;
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _guard(() async {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<void> createAccount(
    String email,
    String password, {
    String? displayName,
  }) async {
    await _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName == null || displayName.isEmpty) return;
      try {
        await credential.user?.updateDisplayName(displayName);
      } catch (_) {
        // The account exists either way; the profile document keeps the name.
      }
    });
  }

  /// Firebase emails a link to its own page for choosing a new password.
  Future<void> sendPasswordReset(String email) async {
    await _guard(() async {
      await _auth.sendPasswordResetEmail(email: email.trim());
    });
  }

  /// Account deletion needs a fresh sign-in. Email accounts pass their
  /// [password].
  Future<void> reauthenticate({String? password}) async {
    final u = user;
    if (u == null) throw const AuthFailure('You are signed out.');
    // A sign-in in the last few minutes already counts as recent.
    final last = u.metadata.lastSignInTime;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 4)) {
      return;
    }
    final ids = u.providerData.map((p) => p.providerId).toSet();
    await _guard(() async {
      if (ids.contains('apple.com')) {
        await u.reauthenticateWithProvider(AppleAuthProvider());
      } else if (ids.contains('google.com')) {
        await _ensureGoogle();
        final account = await GoogleSignIn.instance.authenticate();
        await u.reauthenticateWithCredential(
          GoogleAuthProvider.credential(
            idToken: account.authentication.idToken,
          ),
        );
      } else {
        if (password == null || password.isEmpty) {
          throw const AuthFailure('Enter your password to confirm.');
        }
        await u.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: u.email ?? '',
            password: password,
          ),
        );
      }
    });
  }

  Future<void> signOut() async {
    if (_googleReady) {
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
      debugPrint('Auth failed: ${e.code} ${e.message}');
      throw AuthFailure(_message(e));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('');
      }
      debugPrint('Google sign-in failed: ${e.code.name} ${e.description}');
      throw AuthFailure('Google sign-in did not finish (${e.code.name}).');
    }
  }

  static String _message(FirebaseAuthException e) => switch (e.code) {
    'invalid-email' => 'That email address does not look right.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'That email and password do not match.',
    'email-already-in-use' =>
      'There is already an account with this email. Sign in instead.',
    'weak-password' => 'Choose a longer password, at least 6 characters.',
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
