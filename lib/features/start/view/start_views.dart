import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
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
    controller; // Starts routing.
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.hero,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            const BrandMark(),
            const SizedBox(height: 32),
            Text(
              'Home Vault',
              style: context.textStyles.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your receipts and belongings,\nkept safe in one place',
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const Spacer(flex: 3),
            SizedBox.square(
              dimension: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white.withValues(alpha: 0.6),
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                semanticsLabel: 'Checking sign-in',
              ),
            ),
            const SizedBox(height: 56),
          ],
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
          label: 'Get started',
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
    final p = context.palette;
    final t = context.textStyles;
    return AppPage(
      title: 'Sign in or create an account',
      subtitle:
          'Use the same account on your phone and on the Home Vault website.',
      titleInHeader: false,
      children: [
        const SizedBox(height: 12),
        Obx(
          () => VaultButton.dark(
            label: 'Continue with Apple',
            icon: Icons.apple,
            loading: controller.busy.value == 'apple',
            onPressed: controller.apple,
          ),
        ),
        const SizedBox(height: 14),
        Obx(
          () => _GoogleButton(
            loading: controller.busy.value == 'google',
            onPressed: controller.google,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: p.outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('or', style: TextStyle(color: p.muted)),
            ),
            Expanded(child: Divider(color: p.outline)),
          ],
        ),
        AutofillGroup(
          child: LabeledField(
            label: 'Email address',
            controller: controller.email,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            autofillHints: const [AutofillHints.email],
          ),
        ),
        const SizedBox(height: 14),
        Obx(
          () => VaultButton.secondary(
            label: 'Email me a sign-in link',
            loading: controller.busy.value == 'email',
            onPressed: controller.emailLink,
          ),
        ),
        Obx(() {
          final e = controller.error.value;
          if (e == null) return const SizedBox(height: 12);
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Semantics(
              liveRegion: true,
              child: InfoNote(e, warning: true, icon: Icons.error_outline),
            ),
          );
        }),
        const SizedBox(height: 48),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'By continuing you agree to the',
              style: t.bodyMedium?.copyWith(color: p.muted),
            ),
            LinkButton(
              label: 'Terms',
              onPressed: () => Get.toNamed(Routes.terms),
            ),
            Text('and', style: t.bodyMedium?.copyWith(color: p.muted)),
            LinkButton(
              label: 'Privacy policy',
              onPressed: () => Get.toNamed(Routes.privacy),
            ),
          ],
        ),
      ],
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

/// 04 Check your email
class CheckEmailView extends GetView<CheckEmailController> {
  const CheckEmailView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    return AppPage(
      actions: [
        if (!kIsWeb)
          VaultButton(label: 'Open email app', onPressed: controller.openMail),
        Obx(
          () => VaultButton.secondary(
            label: controller.cooldown.value > 0
                ? 'Send again in ${controller.cooldown.value}s'
                : 'Send the link again',
            onPressed: controller.cooldown.value > 0 ? null : controller.resend,
          ),
        ),
        LinkButton(label: 'Use a different email', onPressed: Get.back),
      ],
      children: [
        const SizedBox(height: 80),
        const Center(child: IconTile(Icons.mail_outline_rounded, size: 120)),
        const SizedBox(height: 32),
        Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: t.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            text: 'We sent a sign-in link to ',
            children: [
              TextSpan(
                text: controller.email,
                style: TextStyle(fontWeight: FontWeight.w800, color: p.ink),
              ),
              TextSpan(
                text: kIsWeb
                    ? '. Open it in this browser to continue.'
                    : '. Tap it on this phone to continue.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: t.titleMedium?.copyWith(
            color: p.muted,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'The link works for 1 hour.',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: p.muted),
        ),
      ],
    );
  }
}

/// Finishing an email sign-in link.
class FinishSignInView extends GetView<FinishSignInController> {
  const FinishSignInView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showBack: false,
      title: 'Signing you in',
      children: [
        Obx(() {
          if (controller.busy.value) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.error.value != null)
                InfoNote(controller.error.value!, warning: true),
              if (controller.needsEmail.value) ...[
                const SizedBox(height: 8),
                Text(
                  'For your security, enter the email address the link was '
                  'sent to.',
                  style: context.textStyles.bodyLarge,
                ),
                LabeledField(
                  label: 'Email address',
                  controller: controller.email,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: 16),
                VaultButton(
                  label: 'Continue',
                  onPressed: () => controller.finish(),
                ),
              ],
              const SizedBox(height: 16),
              LinkButton(
                label: 'Back to sign in',
                onPressed: () => Get.offAllNamed(Routes.signIn),
              ),
            ],
          );
        }),
      ],
    );
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
