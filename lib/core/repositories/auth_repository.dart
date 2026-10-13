import 'dart:convert';

import 'package:get/get.dart';

import '../error/app_exception.dart';
import '../models/user_account.dart';
import '../services/key_value_store.dart';
import '../utils/dates.dart';
import '../utils/ids.dart';

/// Local development stand-in for the auth backend.
///
/// It keeps account profiles on this device and does NOT verify passwords:
/// any well-formed password signs in to an existing account. Replace with a
/// Firebase Auth implementation (the project already initialises Firebase)
/// before release; controllers only depend on this class's public API.
class AuthRepository {
  AuthRepository({required this._store, this._clock = DateTime.now}) {
    _load();
  }

  static const _accountsKey = 'auth.accounts.v1';
  static const _sessionKey = 'auth.session.v1';

  final KeyValueStore _store;
  final Clock _clock;
  final _accounts = <String, UserAccount>{};
  final currentUser = Rxn<UserAccount>();

  bool get isSignedIn => currentUser.value != null;

  Future<UserAccount> signIn(String email, String password) async {
    final account = _accounts[_key(email)];
    if (account == null) {
      throw const AuthException(
        'No account found for this email. Create an account first.',
      );
    }
    return _startSession(account);
  }

  Future<UserAccount> createAccount({
    required String email,
    required String password,
    String? name,
  }) async {
    if (_accounts.containsKey(_key(email))) {
      throw const AuthException(
        'An account already exists for this email. Sign in instead.',
      );
    }
    final trimmedName = name?.trim();
    final account = UserAccount(
      id: Ids.next('user'),
      email: email.trim(),
      name: (trimmedName?.isEmpty ?? true) ? null : trimmedName,
      createdAt: _clock(),
    );
    _accounts[_key(email)] = account;
    return _startSession(account);
  }

  /// Apple and Google return a verified email, so no verification step.
  Future<UserAccount> signInWithProvider(SignInMethod method) async {
    final email = 'you@${method.name}.example';
    final existing = _accounts[_key(email)];
    final account =
        (existing ??
                UserAccount(
                  id: Ids.next('user'),
                  email: email,
                  createdAt: _clock(),
                ))
            .copyWith(
              emailVerified: true,
              methods: {...?existing?.methods, method}
                ..remove(SignInMethod.email),
            );
    _accounts[_key(email)] = account;
    return _startSession(account);
  }

  Future<void> sendVerificationEmail() async {
    if (currentUser.value == null) throw const AuthException('Sign in first.');
  }

  /// Re-reads verification state. The stub treats the link as opened.
  Future<bool> refreshVerification() async {
    final user = currentUser.value;
    if (user == null) return false;
    await _save(user.copyWith(emailVerified: true));
    return true;
  }

  /// Always succeeds for a well-formed address so the screen does not reveal
  /// which emails have accounts.
  Future<void> sendPasswordReset(String email) async {}

  Future<void> reauthenticate(String password) async {
    if (currentUser.value == null) throw const AuthException('Sign in first.');
    if (password.isEmpty) throw const AuthException('Enter your password.');
  }

  Future<void> updateName(String name) async {
    final user = currentUser.value;
    if (user != null) await _save(user.copyWith(name: name.trim()));
  }

  Future<void> signOut() async {
    currentUser.value = null;
    await _store.remove(_sessionKey);
  }

  Future<void> deleteAccount() async {
    final user = currentUser.value;
    if (user == null) return;
    _accounts.remove(_key(user.email));
    await _persistAccounts();
    await signOut();
  }

  String _key(String email) => email.trim().toLowerCase();

  Future<UserAccount> _startSession(UserAccount account) async {
    await _save(account);
    await _store.write(_sessionKey, _key(account.email));
    return account;
  }

  Future<void> _save(UserAccount account) async {
    _accounts[_key(account.email)] = account;
    if (currentUser.value == null ||
        _key(currentUser.value!.email) == _key(account.email)) {
      currentUser.value = account;
    }
    await _persistAccounts();
  }

  Future<void> _persistAccounts() => _store.write(
    _accountsKey,
    jsonEncode([for (final a in _accounts.values) a.toJson()]),
  );

  void _load() {
    final raw = _store.read(_accountsKey);
    if (raw != null) {
      try {
        for (final json in jsonDecode(raw) as List) {
          final account = UserAccount.fromJson(json as Map<String, dynamic>);
          _accounts[_key(account.email)] = account;
        }
      } on Object {
        _accounts.clear();
      }
    }
    final session = _store.read(_sessionKey);
    if (session != null) currentUser.value = _accounts[session];
  }
}
