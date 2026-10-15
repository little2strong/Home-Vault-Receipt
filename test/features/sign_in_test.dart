import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:home_vault_receipt/core/data/auth_repository.dart';
import 'package:home_vault_receipt/core/theme/app_theme.dart';
import 'package:home_vault_receipt/features/start/controller/start_controllers.dart';
import 'package:home_vault_receipt/features/start/view/start_views.dart';

Future<SignInController> pumpAuth(WidgetTester t, Widget page) async {
  Get.testMode = true;
  t.view.physicalSize = const Size(600, 1400) * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final controller = Get.put(
    SignInController(AuthRepository(MockFirebaseAuth())),
  );
  await t.pumpWidget(GetMaterialApp(theme: AppTheme.light, home: page));
  await t.pump();
  return controller;
}

Finder field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.byType(TextFormField),
);

void main() {
  tearDown(Get.reset);

  group('AuthRepository with email and password', () {
    test('creates an account and signs back in', () async {
      final auth = MockFirebaseAuth();
      final repo = AuthRepository(auth);

      await repo.createAccount(' sam@example.com ', 'long-enough-1');
      expect(repo.user, isNotNull);

      await repo.signOut();
      expect(repo.user, isNull);

      await repo.signInWithEmail('sam@example.com', 'long-enough-1');
      expect(repo.user, isNotNull);
    });

    test('sends a password reset', () async {
      final repo = AuthRepository(MockFirebaseAuth());
      await expectLater(repo.sendPasswordReset('sam@example.com'), completes);
    });
  });

  group('03 Sign in form', () {
    testWidgets('shows email and password, not a sign-in link', (t) async {
      await pumpAuth(t, const SignInView());
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.textContaining('sign-in link'), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('asks for a valid email before signing in', (t) async {
      await pumpAuth(t, const SignInView());
      await t.tap(find.text('Sign in'));
      await t.pump();
      expect(find.text('Enter your email address.'), findsOneWidget);
    });

    testWidgets('asks for the password', (t) async {
      await pumpAuth(t, const SignInView());
      await t.enterText(field('Email address'), 'sam@example.com');
      await t.tap(find.text('Sign in'));
      await t.pump();
      expect(find.text('Enter your password.'), findsOneWidget);
    });

    testWidgets('create account asks for a name and matching passwords', (
      t,
    ) async {
      await pumpAuth(t, const SignUpView());
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsNothing);

      await t.enterText(field('Email address'), 'sam@example.com');
      await t.enterText(field('Password'), 'abc');
      await t.enterText(field('Confirm password'), 'abd');
      await t.tap(find.text('Create account'));
      await t.pump();
      expect(find.text('Enter your name.'), findsOneWidget);
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(find.textContaining('characters'), findsNothing);
    });

    testWidgets('forgot password asks for an email first', (t) async {
      await pumpAuth(t, const ForgotPasswordView());
      expect(find.text('Forgot your password?'), findsOneWidget);
      await t.tap(find.text('Send reset link'));
      await t.pump();
      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('the eye button shows and hides the password', (t) async {
      final c = await pumpAuth(t, const SignInView());
      expect(c.showPassword.value, isFalse);
      await t.tap(find.byTooltip('Show password'));
      await t.pump();
      expect(c.showPassword.value, isTrue);
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });
  });
}
