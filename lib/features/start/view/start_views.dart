import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/vault_ui.dart';
import '../controller/start_controllers.dart';

/// 01 Splash
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    controller;
    const bars = SystemUiOverlayStyle(
      statusBarColor: AppColors.hero,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.hero,
      systemNavigationBarDividerColor: AppColors.hero,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: bars,
      child: Scaffold(
        backgroundColor: AppColors.hero,
        body: SizedBox.expand(
          child: ColoredBox(
            color: AppColors.hero,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: const BrandMark(size: 88),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Home Vault',
                      textAlign: TextAlign.center,
                      style: context.textStyles.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Receipts and belongings,\nkept in one place',
                      textAlign: TextAlign.center,
                      style: context.textStyles.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                    const Spacer(flex: 3),
                    Semantics(
                      label: 'Checking sign-in',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: SizedBox(
                          width: 112,
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.18,
                            ),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 02 Welcome
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.textStyles;
    return AppPage(
      showBack: false,
      actions: [
        VaultButton(
          label: 'Create account',
          onPressed: () => Get.toNamed(Routes.signUp),
        ),
        VaultButton.secondary(
          label: 'I already have an account',
          onPressed: () => Get.toNamed(Routes.signIn),
        ),
      ],
      children: [
        const SizedBox(height: AppSizes.lg),
        const _ReceiptIllustration(),
        const SizedBox(height: 40),
        Semantics(
          header: true,
          child: Text(
            'Every receipt and everything you own, in one place',
            style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Snap a receipt, check the details, and Home Vault keeps it safe.',
          style: t.titleMedium?.copyWith(
            color: context.palette.muted,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 28),
        for (final (icon, text) in const [
          (Icons.receipt_long_outlined, 'Find any receipt in seconds'),
          (Icons.verified_user_outlined, 'Reminders before warranties end'),
          (Icons.meeting_room_outlined, 'A room-by-room list for insurance'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                IconTile(icon),
                const SizedBox(width: 16),
                Expanded(child: Text(text, style: t.titleMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReceiptIllustration extends StatelessWidget {
  const _ReceiptIllustration();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget bar(double w, Color c, [double h = 12]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1.15,
        child: Container(
          decoration: BoxDecoration(
            color: p.tonal,
            borderRadius: BorderRadius.circular(32),
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.rotate(
                angle: -0.05,
                child: Container(
                  width: 230,
                  height: 300,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(130, p.hero, 14),
                      const SizedBox(height: 10),
                      bar(84, p.outline),
                      const SizedBox(height: 22),
                      Divider(color: p.outline),
                      for (final w in const [104.0, 76.0, 96.0]) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [bar(w, p.outline), bar(36, p.outline)],
                        ),
                      ],
                      const Spacer(),
                      Divider(color: p.outline),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [bar(56, p.hero), bar(46, p.primary)],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -20,
                bottom: -6,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: p.primary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 03 Sign in
class SignInView extends GetView<SignInController> {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        const _AuthIntro(
          title: 'Welcome back',
          subtitle:
              'Sign in with the account you use on this phone and the web.',
        ),
        EmailPasswordForm(controller: controller),
        const _AuthError(),
        const _OrDivider(),
        const SocialSignInButtons(),
        const SizedBox(height: 8),
        _AuthSwitch(
          prompt: 'New to Home Vault?',
          action: 'Create an account',
          onPressed: controller.openSignUp,
        ),
        const _LegalLine(),
      ],
    );
  }
}

/// Create account. Separate from sign-in so each screen has one job.
class SignUpView extends GetView<SignInController> {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        const _AuthIntro(
          title: 'Create your account',
          subtitle:
              'One account keeps your receipts on this phone and the web.',
        ),
        EmailPasswordForm(controller: controller, create: true),
        const _AuthError(),
        const _OrDivider(),
        const SocialSignInButtons(),
        const SizedBox(height: 8),
        _AuthSwitch(
          prompt: 'Already have an account?',
          action: 'Sign in',
          onPressed: controller.openSignIn,
        ),
        const _LegalLine(),
      ],
    );
  }
}

class _AuthIntro extends StatelessWidget {
  const _AuthIntro({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const BrandRow(),
        const SizedBox(height: 28),
        Semantics(
          header: true,
          child: Text(
            title,
            style: t.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: t.titleMedium?.copyWith(
            color: context.palette.muted,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _AuthError extends GetView<SignInController> {
  const _AuthError();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final message = controller.error.value;
      if (message == null) return const SizedBox(height: 8);
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Semantics(
          liveRegion: true,
          child: InfoNote(message, warning: true, icon: Icons.error_outline),
        ),
      );
    });
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: p.outline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('or', style: TextStyle(color: p.muted)),
          ),
          Expanded(child: Divider(color: p.outline)),
        ],
      ),
    );
  }
}

class SocialSignInButtons extends GetView<SignInController> {
  const SocialSignInButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(
          () => VaultButton.dark(
            label: 'Continue with Apple',
            icon: Icons.apple,
            loading: controller.busy.value == 'apple',
            onPressed: controller.apple,
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => _GoogleButton(
            loading: controller.busy.value == 'google',
            onPressed: controller.google,
          ),
        ),
      ],
    );
  }
}

class _AuthSwitch extends StatelessWidget {
  const _AuthSwitch({
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: TextStyle(color: context.palette.muted)),
        LinkButton(label: action, onPressed: onPressed),
      ],
    );
  }
}

class _LegalLine extends StatelessWidget {
  const _LegalLine();

  @override
  Widget build(BuildContext context) {
    final muted = context.textStyles.bodyMedium?.copyWith(
      color: context.palette.muted,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('By continuing you agree to the ', style: muted),
          LinkButton(
            label: 'Terms',
            onPressed: () => Get.toNamed(Routes.terms),
          ),
          Text(' and ', style: muted),
          LinkButton(
            label: 'Privacy policy',
            onPressed: () => Get.toNamed(Routes.privacy),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight + 4,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: p.surface,
          foregroundColor: p.ink,
          side: BorderSide(color: p.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GoogleMark(),
                  SizedBox(width: 12),
                  Text('Continue with Google'),
                ],
              ),
      ),
    );
  }
}

/// Email and password fields, shared by sign-in (03) and the website (W1).
class EmailPasswordForm extends StatelessWidget {
  const EmailPasswordForm({
    super.key,
    required this.controller,
    this.create = false,
  });

  final SignInController controller;

  /// True on the create-account screen. The website always signs in.
  final bool create;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Obx(() {
      final shown = controller.showPassword.value;
      final busy = controller.busy.value;
      return AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(
              label: 'Email address',
              controller: controller.email,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Password',
              controller: controller.password,
              hint: create
                  ? 'At least ${SignInController.minPasswordLength} characters'
                  : null,
              obscureText: !shown,
              keyboardType: TextInputType.visiblePassword,
              textCapitalization: TextCapitalization.none,
              autofillHints: [
                create ? AutofillHints.newPassword : AutofillHints.password,
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => controller.submitEmail(create: create),
              suffix: IconButton(
                tooltip: shown ? 'Hide password' : 'Show password',
                icon: Icon(
                  shown
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: p.muted,
                ),
                onPressed: controller.showPassword.toggle,
              ),
            ),
            if (!create)
              Align(
                alignment: Alignment.centerRight,
                child: LinkButton(
                  label: 'Forgot password?',
                  onPressed: busy == null ? controller.forgotPassword : null,
                ),
              )
            else
              const SizedBox(height: 20),
            VaultButton(
              label: create ? 'Create account' : 'Sign in',
              loading: busy == 'email',
              onPressed: () => controller.submitEmail(create: create),
            ),
          ],
        ),
      );
    });
  }
}

/// 05 Notifications permission
class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    return AppPage(
      showBack: false,
      actions: [
        Obx(
          () => VaultButton(
            label: 'Turn on reminders',
            loading: controller.busy.value,
            onPressed: controller.turnOn,
          ),
        ),
        LinkButton(label: 'Not now', onPressed: controller.notNow),
        Text(
          'You can change this any time in Settings.',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: p.muted),
        ),
      ],
      children: [
        const SizedBox(height: 80),
        const ExcludeSemantics(
          child: _SampleNotification(
            title: 'Warranty ends in 2 weeks',
            body:
                'Dyson V12 vacuum · bought at Argos. Book a repair now if it '
                'has a fault.',
          ),
        ),
        const SizedBox(height: 12),
        const ExcludeSemantics(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Opacity(
              opacity: 0.7,
              child: _SampleNotification(
                title: 'Last day to return',
                body: 'Wool coat · Marks & Spencer',
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Semantics(
          header: true,
          child: Text(
            'Get a nudge before deadlines',
            style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "We only send reminders for warranties and returns you've "
          'confirmed. No marketing.',
          style: t.titleMedium?.copyWith(
            color: p.muted,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SampleNotification extends StatelessWidget {
  const _SampleNotification({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(
            Icons.home_outlined,
            color: p.primary,
            iconColor: Colors.white,
            size: 44,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleMedium),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: p.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
