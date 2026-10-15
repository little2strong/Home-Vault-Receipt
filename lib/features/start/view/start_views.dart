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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const BrandMark(size: 64),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Home Vault',
                      textAlign: TextAlign.center,
                      style: context.textStyles.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Receipts and belongings,\nkept in one place',
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
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
        const SizedBox(height: 8),
        const _ReceiptIllustration(),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            'Every receipt and everything you own, in one place',
            style: t.headlineSmall?.copyWith(
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Snap a receipt, check the details, and Home Vault keeps it safe.',
          style: t.bodyLarge?.copyWith(
            color: context.palette.muted,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        for (final (icon, text) in const [
          (Icons.receipt_long_outlined, 'Find any receipt in seconds'),
          (Icons.verified_user_outlined, 'Reminders before warranties end'),
          (Icons.meeting_room_outlined, 'A room-by-room list for insurance'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                IconTile(icon, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
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
      child: SizedBox(
        height: 188,
        child: Container(
          decoration: BoxDecoration(
            color: p.tonal,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.rotate(
                angle: -0.05,
                child: Container(
                  width: 140,
                  height: 168,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(84, p.hero, 10),
                      const SizedBox(height: 8),
                      bar(52, p.outline, 8),
                      const SizedBox(height: 14),
                      Divider(color: p.outline, height: 1),
                      for (final w in const [68.0, 48.0, 60.0]) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            bar(w, p.outline, 8),
                            bar(24, p.outline, 8),
                          ],
                        ),
                      ],
                      const Spacer(),
                      Divider(color: p.outline, height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [bar(36, p.hero, 8), bar(28, p.primary, 8)],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -12,
                bottom: -4,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: p.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 26,
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
          subtitle: 'Sign in to see your receipts, warranties and belongings.',
        ),
        EmailPasswordForm(controller: controller),
        const _AuthError(),
        const _OrDivider(),
        const SocialSignInButtons(),
        const SizedBox(height: 16),
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
              'It takes a minute. Your vault stays in sync on this phone and '
              'the web.',
        ),
        EmailPasswordForm(controller: controller, create: true),
        const _AuthError(),
        const _OrDivider(label: 'or sign up with'),
        const SocialSignInButtons(),
        const SizedBox(height: 16),
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

/// Forgot password: Firebase emails a link to its page for a new password.
class ForgotPasswordView extends GetView<SignInController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        Obx(() {
          final sentTo = controller.resetSentTo.value;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: sentTo == null
                ? const _ResetRequest(key: ValueKey('request'))
                : _ResetSent(sentTo, key: const ValueKey('sent')),
          );
        }),
      ],
    );
  }
}

class _ResetRequest extends GetView<SignInController> {
  const _ResetRequest({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AuthIntro(
          icon: Icons.lock_reset_rounded,
          title: 'Forgot your password?',
          subtitle:
              "Enter the email you use for Home Vault and we'll send you a "
              'link to choose a new one.',
        ),
        Obx(
          () => LabeledField(
            label: 'Email address',
            controller: controller.email,
            hint: 'you@example.com',
            error: controller.emailError.value,
            prefixIcon: const Icon(Icons.mail_outline_rounded),
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.send,
            onChanged: (_) => controller.emailError.value = null,
            onSubmitted: (_) => controller.sendReset(),
          ),
        ),
        const SizedBox(height: 24),
        Obx(
          () => VaultButton(
            label: 'Send reset link',
            icon: Icons.send_rounded,
            loading: controller.busy.value == 'reset',
            onPressed: controller.sendReset,
          ),
        ),
        const _AuthError(),
        const SizedBox(height: 8),
        Center(
          child: LinkButton(label: 'Back to sign in', onPressed: Get.back),
        ),
      ],
    );
  }
}

class _ResetSent extends GetView<SignInController> {
  const _ResetSent(this.email, {super.key});

  final String email;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final body = context.textStyles.bodyLarge?.copyWith(
      color: p.muted,
      height: 1.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AuthIntro(
          icon: Icons.mark_email_read_outlined,
          title: 'Check your email',
        ),
        Semantics(
          liveRegion: true,
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: "If there's a Home Vault account for "),
                TextSpan(
                  text: email,
                  style: TextStyle(color: p.ink, fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                  text: ", we've sent a link to choose a new password.",
                ),
              ],
            ),
            style: body,
          ),
        ),
        const SizedBox(height: 20),
        const InfoNote(
          "It can take a few minutes. If you can't see it, check your spam "
          'or junk folder.',
          icon: Icons.schedule_rounded,
        ),
        const SizedBox(height: 24),
        VaultButton(label: 'Back to sign in', onPressed: Get.back),
        const SizedBox(height: 12),
        Obx(() {
          final wait = controller.resendIn.value;
          return VaultButton.secondary(
            label: wait > 0 ? 'Resend link in ${wait}s' : 'Resend link',
            loading: controller.busy.value == 'reset',
            onPressed: wait > 0 ? null : controller.resendReset,
          );
        }),
        const _AuthError(),
        const SizedBox(height: 8),
        Center(
          child: LinkButton(
            label: 'Use a different email',
            onPressed: controller.useDifferentEmail,
          ),
        ),
      ],
    );
  }
}

/// Logo (or an [icon] tile), a large title and a muted line under it.
class _AuthIntro extends StatelessWidget {
  const _AuthIntro({required this.title, this.subtitle, this.icon});

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon == null) const BrandRow() else IconTile(icon!, size: 56),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            title,
            style: t.headlineSmall?.copyWith(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: t.bodyLarge?.copyWith(
              color: context.palette.muted,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
        SizedBox(height: subtitle == null ? 8 : 12),
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
  const _OrDivider({this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: p.outline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(label, style: TextStyle(color: p.muted)),
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
    return Obx(
      () => _GoogleButton(
        loading: controller.busy.value == 'google',
        onPressed: controller.google,
      ),
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
        Text(
          prompt,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.palette.muted,
          ),
        ),
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
      height: AppSizes.buttonHeight,
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

/// Email and password fields, shared by sign-in (03) and create account.
class EmailPasswordForm extends StatelessWidget {
  const EmailPasswordForm({
    super.key,
    required this.controller,
    this.create = false,
  });

  final SignInController controller;

  /// True on the create-account screen.
  final bool create;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    void submit() => c.submitEmail(create: create);
    return Obx(() {
      final shown = c.showPassword.value;
      final busy = c.busy.value;
      final toggle = _VisibilityToggle(
        shown: shown,
        onPressed: c.showPassword.toggle,
      );
      return AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (create)
              LabeledField(
                label: 'Full name',
                controller: c.name,
                hint: 'e.g. Sam Taylor',
                error: c.nameError.value,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                onChanged: (_) => c.nameError.value = null,
              ),
            LabeledField(
              label: 'Email address',
              controller: c.email,
              hint: 'you@example.com',
              error: c.emailError.value,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              onChanged: (_) => c.emailError.value = null,
            ),
            LabeledField(
              label: 'Password',
              controller: c.password,
              hint: create ? 'Create a password' : 'Enter your password',
              error: c.passwordError.value,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              obscureText: !shown,
              keyboardType: TextInputType.visiblePassword,
              textCapitalization: TextCapitalization.none,
              autofillHints: [
                create ? AutofillHints.newPassword : AutofillHints.password,
              ],
              textInputAction: create
                  ? TextInputAction.next
                  : TextInputAction.done,
              onChanged: (_) => c.passwordError.value = null,
              onSubmitted: create ? null : (_) => submit(),
              suffix: toggle,
            ),
            if (create) ...[
              LabeledField(
                label: 'Confirm password',
                controller: c.confirmPassword,
                hint: 'Type it again',
                error: c.confirmError.value,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                obscureText: !shown,
                keyboardType: TextInputType.visiblePassword,
                textCapitalization: TextCapitalization.none,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onChanged: (_) => c.confirmError.value = null,
                onSubmitted: (_) => submit(),
                suffix: toggle,
              ),
              const SizedBox(height: 24),
            ] else
              Align(
                alignment: Alignment.centerRight,
                child: LinkButton(
                  label: 'Forgot password?',
                  underline: false,
                  onPressed: busy == null ? c.openForgotPassword : null,
                ),
              ),
            VaultButton(
              label: create ? 'Create account' : 'Sign in',
              loading: busy == 'email',
              onPressed: busy == null ? submit : null,
            ),
          ],
        ),
      );
    });
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.shown, required this.onPressed});

  final bool shown;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: shown ? 'Hide password' : 'Show password',
    icon: Icon(
      shown ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      color: context.palette.muted,
    ),
    onPressed: onPressed,
  );
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
