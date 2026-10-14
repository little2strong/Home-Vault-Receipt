import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../controller/capture_flow.dart';

class ReadingController extends GetxController {
  CaptureFlow get flow => CaptureFlow.to;
  final failed = false.obs;
  bool _cancelled = false;

  @override
  void onReady() {
    super.onReady();
    run();
  }

  Future<void> run() async {
    failed.value = false;
    final ok = await flow.read();
    if (_cancelled) return;
    if (!ok) {
      failed.value = true;
      return;
    }
    await Get.offNamed(Routes.reviewDetails);
  }

  void typeItMyself() {
    _cancelled = true;
    Get.offNamed(Routes.reviewDetails);
  }
}

/// 11 Reading receipt: progress while text is recognised on the phone.
class ReadingView extends GetView<ReadingController> {
  const ReadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    return AppPage(
      showBack: false,
      actions: [
        Obx(
          () => controller.failed.value
              ? VaultButton(label: 'Try again', onPressed: controller.run)
              : const SizedBox.shrink(),
        ),
        LinkButton(
          label: 'Skip and type it myself',
          onPressed: controller.typeItMyself,
        ),
      ],
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => controller.flow.discard(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 17)),
          ),
        ),
        const SizedBox(height: 40),
        const Center(child: _ScanningPaper()),
        const SizedBox(height: 40),
        Obx(
          () => Text(
            controller.failed.value
                ? "We couldn't read this receipt"
                : 'Reading your receipt',
            textAlign: TextAlign.center,
            style: t.headlineMedium,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            controller.failed.value
                ? 'The text may be faded or blurred. Try again in better light, '
                      'or type in what you can see.'
                : 'This happens on your phone. It takes a few seconds.',
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(
              color: p.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Obx(() {
          final step = controller.flow.readingStep.value;
          final failed = controller.failed.value;
          return Semantics(
            liveRegion: true,
            child: Column(
              children: [
                for (final (i, label) in const [
                  (0, 'Finding the text'),
                  (1, 'Picking out shop, date and items'),
                  (2, 'Getting it ready for you to check'),
                ])
                  _Step(
                    label: label,
                    state: step > i
                        ? _State.done
                        : (step == i && !failed
                              ? _State.active
                              : _State.waiting),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

enum _State { done, active, waiting }

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.state});

  final String label;
  final _State state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final icon = switch (state) {
      _State.done => CircleAvatar(
        radius: 18,
        backgroundColor: p.primary,
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
      ),
      _State.active => SizedBox.square(
        dimension: 36,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: p.primary,
          backgroundColor: p.tonal,
        ),
      ),
      _State.waiting => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: p.outline, width: 3),
        ),
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 32),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: context.textStyles.titleMedium?.copyWith(
                color: state == _State.waiting ? p.muted : p.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningPaper extends StatefulWidget {
  const _ScanningPaper();

  @override
  State<_ScanningPaper> createState() => _ScanningPaperState();
}

class _ScanningPaperState extends State<_ScanningPaper>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget bar(double w, Color c) => Container(
      width: w,
      height: 12,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return ExcludeSemantics(
      child: Container(
        width: 210,
        height: 270,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.outline),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                bar(100, p.hero),
                bar(64, p.outline),
                const SizedBox(height: 14),
                for (var i = 0; i < 3; i++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [bar(90, p.outline), bar(36, p.outline)],
                  ),
              ],
            ),
            AnimatedBuilder(
              animation: _anim,
              builder: (_, _) => Positioned(
                top: 8 + _anim.value * 190,
                left: -22,
                right: -22,
                child: Container(height: 3, color: p.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
